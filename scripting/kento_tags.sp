// command !goldtag
// name must have ARENA.1TAP.RO
// https://hastebin.com/heqonoroji.cpp
// chat tag from https://github.com/Heyter/CountryTag

#include <sourcemod>
#include <cstrike>
#include <clientprefs>
#include <basecomm>
#include <colors> 

#define MAX_TAG_COUNT 1000

#pragma newdecls required

int Selected[MAXPLAYERS + 1] = {-1, ...};
int TagCount;

char sTagName[MAX_TAG_COUNT+1][PLATFORM_MAX_PATH + 1];
char name_required[512];

Handle tag_cookie;
Handle tag_menu;

float g_fLastChatMsg[MAXPLAYERS + 1];

ConVar Cvar_name;

public Plugin myinfo =
{
	name = "[CS:GO] Client Tags",
	author = "Kento",
	version = "1.1",
	description = "Fuck you reseller ARENA.1TAP.RO",
	url = "http://steamcommunity.com/id/kentomatoryoshika/"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_goldtag", Command_Tag, "Select Your Tag");
	
	RegAdminCmd("sm_testtag", Command_Test, ADMFLAG_ROOT, "Test tag");
	
	tag_cookie = RegClientCookie("tag_cookie", "Player's Tag", CookieAccess_Private);
	
	AddCommandListener(ChatSay, "say");
	AddCommandListener(ChatSay, "say_team");
	
	LoadTranslations("kento.tags.phrases");
	
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	
	Cvar_name = CreateConVar("sm_tag_name", "", "Name required to use the tag, blank = disabled");
	Cvar_name.AddChangeHook(OnCvarChange);
	
	AutoExecConfig();
	
	for(int i = 1; i <= MaxClients; i++)
	{ 
		if(IsValidClient(i) && !IsFakeClient(i))	OnClientCookiesCached(i);
	}
}

public void OnMapStart()
{
	CreateTimer(1.0, SetClanTag, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
}

public void OnConfigsExecuted()
{
	Cvar_name.GetString(name_required, sizeof(name_required));
	LoadConfig();
}

void LoadConfig()
{
	char Configfile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, Configfile, sizeof(Configfile), "configs/kento_tags.ini");
	
	if (!FileExists(Configfile))
	{
		SetFailState("Fatal error: Unable to open generic configuration file \"%s\"!", Configfile);
	}
	
	Handle fileh = OpenFile(Configfile, "r");
	
	char line[PLATFORM_MAX_PATH + 1];
	
	TagCount = 1;
	//strcopy(sTagName[TagCount], sizeof(sTagName[]), "YOUTUBER");
	TagCount++;
	
	while (ReadFileLine(fileh, line, sizeof(line)))
	{
		// Remove whitespaces and empty lines
		TrimString(line);
		ReplaceString(line, sizeof(line), " ", "", false);
		
		// Skip comments
		if (line[0] != '/')
		{
			strcopy(sTagName[TagCount], sizeof(sTagName[]), line);
			TagCount++;
		}
	}
	CloseHandle(fileh);
}

public void OnClientCookiesCached(int client)
{
	if(!IsValidClient(client) && IsFakeClient(client))
		return;
		
	char scookie[8];
	GetClientCookie(client, tag_cookie, scookie, sizeof(scookie));
	
	// Player already selected tag
	if(!StrEqual(scookie, ""))
	{
		int icookie = StringToInt(scookie);
		Selected[client] = icookie;
	}
	else
	{
		Selected[client] = 0;
		SetClientCookie(client, tag_cookie, "0");
	}
	
	/*
	// Player join this server first time and he is NOT youtuber
	if(StrEqual(scookie,"") && !IsYoutuber(client))
	{
		Selected[client] = 0;
		SetClientCookie(client, tag_cookie, "0");
	}
	
	// Player join this server first time and he is youtuber
	if(StrEqual(scookie,"") && IsYoutuber(client))
	{
		Selected[client] = 1;
		SetClientCookie(client, tag_cookie, "1");
	}
	*/
}

public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && !IsFakeClient(i))	CPrintToChat(i, "%T", "Advert", i);
	}
}

public Action Command_Tag(int client,int args)
{
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		// Player can use client tag
		if(IsNameGold(client))
		{
			tag_menu = new Menu(TAGMenuHandler);
	
			char menutitle[512];
			Format(menutitle, sizeof(menutitle), "%T", "Select Your Tag", client);
			SetMenuTitle(tag_menu, menutitle);
			
			// No tag
			char notag[PLATFORM_MAX_PATH];
			Format(notag, sizeof(notag), "%T", "NO Tag", client);
			AddMenuItem(tag_menu, "0", notag);
			
			//if(IsYoutuber(client))	AddMenuItem(tag_menu, "1", sTagName[1]);
			
			// Add tag
			for(int i = 2; i < TagCount; i++)
			{
				char tag_id[PLATFORM_MAX_PATH];
				Format(tag_id, sizeof(tag_id), "%i", i);
				AddMenuItem(tag_menu, tag_id, sTagName[i]);
			}
		
			DisplayMenu(tag_menu, client, 0);
		}
		else CPrintToChat(client, "%T", "Please Add", client);
	
	}
	return Plugin_Handled;
}

public int TAGMenuHandler(Menu menu, MenuAction action, int client,int param)
{
	if(action == MenuAction_Select)
	{
		char stag_id[10];
		GetMenuItem(menu, param, stag_id, sizeof(stag_id));
		
		int itag_id = StringToInt(stag_id, sizeof(stag_id));
		
		if(itag_id == 0)	CPrintToChat(client, "%T", "You Removed", client);
		else if(itag_id > 0)	CPrintToChat(client, "%T", "You Tag Is", client, sTagName[itag_id]);

		Selected[client] = itag_id;
		SetClientCookie(client, tag_cookie, stag_id);
	}
}

// Set tag on scoreboard
public Action SetClanTag(Handle timer, any client)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && !IsFakeClient(i))	CreateTimer(0.1, SetClanTag2, i, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action SetClanTag2(Handle timer, any client)
{
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		int tag = Selected[client];
		
		if(IsNameGold(client) && tag > 0)	CS_SetClientClanTag(client, sTagName[tag]);
		//else CS_SetClientClanTag(client, "");
	}
}

public Action Command_Test(int client,int args)
{
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		PrintToChat(client, "Check your console");
		
		for(int i = 1; i < TagCount; i++)
		{
			char stag_id[PLATFORM_MAX_PATH];
			Format(stag_id, sizeof(stag_id), "%i", i);
			PrintToConsole(client, "ID %i, Name %s", i, sTagName[i]);
		}
	}
	return Plugin_Handled;
}
	
// chat tag from https://github.com/Heyter/CountryTag
public Action ChatSay(int client, const char[] command, int args)
{
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		char tag[PLATFORM_MAX_PATH + 1], text[512], textcolor[1024];
		int itag = Selected[client];
		tag = sTagName[itag];
		
		// No tag & no name
		if(itag < 0 || !IsNameGold(client))
			return Plugin_Continue;
		
		int flood = (GetEngineTime() - g_fLastChatMsg[client]) < 0.75;
		int mute = BaseComm_IsClientGagged(client);
			
		if (mute || flood)
		{
			if (mute) CPrintToChat(client, "%t", "MUTE");
			return Plugin_Handled;
		}
		g_fLastChatMsg[client] = GetEngineTime();
			
		text[0] = '\0';
		int team = GetClientTeam(client);
		int alive = IsPlayerAlive(client);
			
		GetCmdArgString(text, sizeof(text));
		StripQuotes(text);
		TrimString(text);
			
		if (strcmp(text, " ") == 0 || strcmp(text, "") == 0 || strlen(text) == 0)
		{
			return Plugin_Handled;
		}
			
		if (StrContains(text, "@") == 0 || StrContains(text, "/") == 0)
		{
			return Plugin_Continue;
		}
			
		FormatEx(textcolor, sizeof(textcolor), "%s", text);
			
		if (strcmp(command, "say") == 0)
		{
			if (team < 2) 
			{
				if(itag == 1)
					FormatEx(text, sizeof(text), "%t", "SPECTATOR_SAY_TEAM_2", tag, client, textcolor);
					
				else FormatEx(text, sizeof(text), "%t", "SPECTATOR_SAY_TEAM", tag, client, textcolor);
			}
			else
			{
				if (alive) 
				{
					if(itag == 1)
						FormatEx(text, sizeof(text), "%t", "ALIVE_CHAT_2", tag, client, textcolor);
					
					else FormatEx(text, sizeof(text), "%t", "ALIVE_CHAT", tag, client, textcolor);
				}
				else 
				{
					if(itag == 1)
						FormatEx(text, sizeof(text), "%t", "DEAD_2", tag, client, textcolor);
						
					else FormatEx(text, sizeof(text), "%t", "DEAD", tag, client, textcolor);
				}
			}
			CPrintToChatAllEx(client, "%s", text);
			return Plugin_Handled;
		}
			
		else if(strcmp(command, "say_team") == 0)
		{
			switch(team)
			{
				case 1:
				{
					if(itag == 1)
						FormatEx(text, sizeof(text), "%t", "SPECTATOR_SAY_2", tag, client, textcolor);
					else FormatEx(text, sizeof(text), "%t", "SPECTATOR_SAY", tag, client, textcolor);
				}
				case 2:
				{
					if (alive) 
					{
						if(itag == 1)
							FormatEx(text, sizeof(text), "%t", "TEAM_T_2", tag, client, textcolor);
						else FormatEx(text, sizeof(text), "%t", "TEAM_T", tag, client, textcolor);
					}
					else 
					{
						if(itag == 1)
							FormatEx(text, sizeof(text), "%t", "DEAD_TEAM_T_2", tag, client, textcolor);
						else FormatEx(text, sizeof(text), "%t", "DEAD_TEAM_T", tag, client, textcolor);
					}
				}
				case 3:
				{
					if (alive) 
					{
						if(itag == 1)
							FormatEx(text, sizeof(text), "%t", "TEAM_CT_2", tag, client, textcolor);
						else FormatEx(text, sizeof(text), "%t", "TEAM_CT", tag, client, textcolor);
					}
					else 
					{
						if(itag == 1)
							FormatEx(text, sizeof(text), "%t", "DEAD_TEAM_CT_2", tag, client, textcolor);
						else FormatEx(text, sizeof(text), "%t", "DEAD_TEAM_CT", tag, client, textcolor);
					}
				}
			}
				
			for (int x = 1; x <= MaxClients; x++)
			{
				if (IsClientInGame(x) && GetClientTeam(x) == team)
				{
					CPrintToChatEx(x, x, "%s", text);
				}
			}
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public void OnClientPutInServer(int client)
{
	g_fLastChatMsg[client] = 0.0;
	if (IsValidClient(client) && !IsFakeClient(client))	OnClientCookiesCached(client);
}

stock bool IsValidClient(int client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	if (!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}

bool IsNameGold(int client)
{
	char clientname [PLATFORM_MAX_PATH];
	GetClientName(client, clientname, sizeof(clientname));

	// name required is blank, everyone can use it
	if (StrEqual(name_required, "") || StrEqual(name_required, " "))	return true;
	// not balnk, check players' name
	else
	{
		if(StrContains(clientname, name_required, false) != -1)
		{
			return true;
		}
		else return false;
	}
}

public void OnCvarChange(ConVar convar, char[] oldValue, char[] newValue)
{
	if (convar == Cvar_name)
	{
		Cvar_name.GetString(name_required, sizeof(name_required));
	}
}

/*
//abcfn
bool IsYoutuber(int client)
{
	if(CheckCommandAccess(client, "kento_tag_admin", ADMFLAG_RESERVATION, true) && 
		CheckCommandAccess(client, "kento_tag_admin", ADMFLAG_GENERIC, true) && 
		CheckCommandAccess(client, "kento_tag_admin", ADMFLAG_KICK, true) && 
		CheckCommandAccess(client, "kento_tag_admin", ADMFLAG_SLAY, true) && 
		CheckCommandAccess(client, "kento_tag_admin", ADMFLAG_CHEATS, true))
		return true;

	else return false;
}
*/
/*
"reservation"	"a"			//Reserved slots
		"generic"		"b"			//Generic admin, required for admins
		"kick"			"c"			//Kick other players
		"ban"			"d"			//Banning other players
		"unban"			"e"			//Removing bans
		"slay"			"f"			//Slaying other players
		"changemap"		"g"			//Changing the map
		"cvars"			"h"			//Changing cvars
		"config"		"i"			//Changing configs
		"chat"			"j"			//Special chat privileges
		"vote"			"k"			//Voting
		"password"		"l"			//Password the server
		"rcon"			"m"			//Remote console
		"cheats"		"n"			//Change sv_cheats and related commands
*/