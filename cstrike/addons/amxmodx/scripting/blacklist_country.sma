#pragma compress 1
#pragma tabsize  4
#include <amxmodx> 
#include <amxmisc>
#include <geoip>

#pragma semicolon 1

new const PLUGIN_NAME	[] = "Blacklist Country";
new const PLUGIN_VERSION[] = "0.1";
new const PLUGIN_AUTHOR [] = "Aoi.Kagase";
new const BLACKLIST		[] = "blacklist_country.ini";
new Array:g_Blacklists;


public plugin_init()
{ 
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);
	create_cvar	   (PLUGIN_NAME, PLUGIN_VERSION, FCVAR_SPONLY|FCVAR_SERVER);
}

public plugin_cfg()
{
	new iniFile	[64];
	new sConfigDir	[64];
	get_configsdir(sConfigDir, charsmax(sConfigDir));
	formatex(iniFile, charsmax(iniFile), "%s/%s", sConfigDir, BLACKLIST);

	load_blacklist_country(iniFile);
}

load_blacklist_country(sFileName[])
{ 
	if (!file_exists(sFileName))
		return;

	new sRec[4];
	new sRecLen 	= charsmax(sRec);

	new fp 			= fopen(sFileName, "r");

	g_Blacklists 	= ArrayCreate(4);

	while(!feof(fp))
	{
		if (fgets(fp, sRec, sRecLen) == 0)
			continue;

		trim(sRec);

		// Comment Line ; or # or //
		// Empty Line
		if (sRec[0] == ';'
		||  sRec[0] == '#'
		|| (strlen(sRec) >= 2 && (sRec[0] == '/' && sRec[0] == '/'))
		||  strlen(sRec) == 0)
			continue;

		ArrayPushString(g_Blacklists, sRec);
	}
	fclose(fp);
} 

stock bool:IsLocalIp(IP[MAX_IP_LENGTH])
{
	new tIP[MAX_IP_LENGTH];
	
	copy(tIP,3,IP);

	if(equal(tIP,"10.") || equal(tIP,"127"))
		return true;

	copy(tIP,7,IP);

	if(equal(tIP,"192.168"))
		return true;

	return false;
}

public client_connect(id)
{
	new userip	[MAX_IP_LENGTH];
	get_user_ip(id, userip, charsmax(userip),1);		
	new CC		[4];
	new country	[45];

	geoip_code3_ex(userip, CC);
	geoip_country_ex(userip, country, charsmax(country), 1);

	if(strlen(userip) == 0)
	{
		get_user_ip(id, userip, charsmax(userip),1);		
		if(!IsLocalIp(userip))
			log_amx("%s made a error when passed though geoip", userip);
		return PLUGIN_HANDLED;
	}

	if (ArrayFindString(g_Blacklists, CC) > -1)
	{
		server_cmd("kick #%d Your connecting country (%s) is denied.",get_user_userid(id), country);
		client_print(0, print_chat, "%n was kicked because he is from %s", id, country);
	}
	return PLUGIN_HANDLED;
}