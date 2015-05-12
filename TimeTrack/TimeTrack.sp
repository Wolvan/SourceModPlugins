/* Copyright
 * Category: None
 * 
 * Easy Player Time Tracker by Wolvan
 * Contact: wolvan1@gmail.com
 * 
 * Warning, this code is a mass and I am far too lazy to fix it right now
*/

/* Includes
 * Category: Preprocessor
 *  
 * Includes the necessary SourceMod modules
 * 
*/
#include <sourcemod>

/* Plugin constants definiton
 * Category: Preprocessor
 * 
 * Define Plugin Constants for easier usage and management in the code.
 * 
*/
#define PLUGIN_NAME "Playertime Tracker"
#define PLUGIN_VERSION "1.0.0"
#define PLUGIN_AUTHOR "Wolvan"
#define PLUGIN_DESCRIPTION "Track playtime of any User!"
#define PLUGIN_URL "NULL"
#define PLUGIN_CONFIG "cfg/sourcemod/plugin.PlayertimeTracker.cfg"
#define PLUGIN_DATA_STORAGE "PlayertimeTracker"
#define PERMISSIONNODE_BASE "PlayertimeTracker"

/* Variable creation
 * Category: Storage
 *  
 * Create Storage Variable for Database Handles and Queries
 * 
*/
new String:WriteQuery[] = "INSERT INTO sm_playertime(steamid, time) VALUES(?, ?)";
new String:LogQuery[] = "INSERT INTO sm_playertimelog (steamid, time, date) VALUES (?, ?, ?)"
new String:SteamidQuery[] = "SELECT steamid FROM sm_playertime";
new String:ReadlogQuery[] = "SELECT time FROM sm_playertimelog WHERE steamid = ? AND date >= ?";
new String:ReadQuery[] = "SELECT time FROM sm_playertime WHERE steamid = ?";
new String:UpdateQuery[] = "UPDATE sm_playertime SET time = ? WHERE steamid = ?"
new String:CheckQuery[] = "SELECT EXISTS (SELECT * FROM sm_playertime WHERE steamid = ?)";
new String:ForwardQuery[] = "SELECT protected_from_forward, already_ran_on FROM sm_playertimeforwards WHERE steamid = ?"
new String:init_mysql1[] = "CREATE TABLE IF NOT EXISTS sm_playertime (id integer NOT NULL AUTO_INCREMENT, steamid text NOT NULL, time integer NOT NULL DEFAULT 0, PRIMARY KEY (id))";
new String:init_mysql2[] = "CREATE TABLE IF NOT EXISTS sm_playertimelog (id integer NOT NULL AUTO_INCREMENT, steamid text NOT NULL, time integer NOT NULL DEFAULT 0, date integer NOT NULL DEFAULT 0, PRIMARY KEY (id))";
new String:init_mysql3[] = "CREATE TABLE IF NOT EXISTS sm_playertimeforwards (id integer NOT NULL AUTO_INCREMENT, steamid text NOT NULL, protected_from_forward integer DEFAULT 0, already_ran_on integer DEFAULT 0, PRIMARY KEY (id))";
new String:init_sqlite1[] = "CREATE TABLE IF NOT EXISTS sm_playertime (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, steamid TEXT NOT NULL, time INTEGER NOT NULL DEFAULT 0)";
new String:init_sqlite2[] = "CREATE TABLE IF NOT EXISTS sm_playertimelog (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, steamid TEXT NOT NULL, time INTEGER NOT NULL DEFAULT 0, date INTEGER NOT NULL DEFAULT 0)";
new String:init_sqlite3[] = "CREATE TABLE IF NOT EXISTS sm_playertimeforwards (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, steamid TEXT NOT NULL, protected_from_forward INTEGER DEFAULT 0, already_ran_on INTEGER DEFAULT 0)";
new String:exists_mysql[] = "SELECT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'sm_playertime')";
new String:exists_sqlite[] = "SELECT count(*) FROM sqlite_master WHERE type='table' AND name='sm_playertime'";
new Handle:db = INVALID_HANDLE;
new Handle:db_PrepareStmtRead = INVALID_HANDLE;
new Handle:db_PrepareStmtUpdate = INVALID_HANDLE;
new Handle:db_PrepareStmtWrite = INVALID_HANDLE;
new Handle:db_PrepareStmtLog = INVALID_HANDLE;
new Handle:db_PrepareStmtLogread = INVALID_HANDLE;
new Handle:db_PrepareStmtCheck = INVALID_HANDLE;
new Handle:db_PrepareStmtForward = INVALID_HANDLE;
new Handle:timer_forwardTimer = INVALID_HANDLE;

/* ConVar Handle creation
 * Category: Storage
 * 
 * Create the Variables to store the ConVar Handles in.
 * 
*/
new Handle:g_enabled = INVALID_HANDLE;
new Handle:g_timeFormat = INVALID_HANDLE;
new Handle:g_threshold = INVALID_HANDLE;
new Handle:g_minTime = INVALID_HANDLE;
new Handle:g_enableForward = INVALID_HANDLE;
new Handle:g_runForwardMultipleTimes = INVALID_HANDLE;

/* Forward Handle creation
 * Category: Storage
 * 
 * Create the Handles for the Forward Calls
 * 
*/
new Handle:forward_clientNotSeen = INVALID_HANDLE;

/* Create plugin instance
 * Category: Plugin Instance
 *  
 * Tell SourceMod about my Plugin
 * 
*/
public Plugin:myinfo = {
	name 			= PLUGIN_NAME,
	author 			= PLUGIN_AUTHOR,
	description 	= PLUGIN_DESCRIPTION,
	version 		= PLUGIN_VERSION,
	url 			= PLUGIN_URL
}

/* Plugin starts
 * Category: Plugin Callback
 * 
 * Do basic startup work like loading translations, creating convars and registering Commands
 * as well as trying to initialize Database Connections
 * 
*/
public OnPluginStart() {
	// load translations
	LoadTranslations("common.phrases");
	
	// create the version and tracking ConVar
	g_enabled = CreateConVar("timetrack_enabled", "1", "Enable Plugin Functionality", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_timeFormat = CreateConVar("timetrack_format", "%i:%02i:%02i:%02i", "Format to show Time in.", FCVAR_NOTIFY);
	g_threshold = CreateConVar("timetrack_threshold", "14", "Last X days that sm_playertimetimespan will check", FCVAR_NOTIFY, true, 0.1);
	g_minTime = CreateConVar("timetrack_minimum_time", "60", "Minimum required online time to prevent forward firing on yourself", FCVAR_NOTIFY, true, 0.0)
	g_enableForward = CreateConVar("timetrack_enable_forward", "1", "Fire Forward on Players that have not been online for timetrack_minimum_time", FCVAR_NOTIFY, true, 0.0, true, 1.0)
	g_runForwardMultipleTimes = CreateConVar("timetrack_run_forward_multiple", "1", "Fire Forward multiple times", FCVAR_NOTIFY, true, 0.0, true, 1.0)
	HookConVarChange(g_enableForward, ForwardEnableChanged);
	
	// register console commands
	RegAdminCmd("sm_playertime", GetPlayerTime, ADMFLAG_KICK, "Get Online Time of an online Player or a SteamID2.")
	RegAdminCmd("sm_playertimetimespan", GetPlayerTimeTwoWeeks, ADMFLAG_KICK, "Get Online Time of an online Player or a SteamID2 from the last 2 weeks.")
	RegAdminCmd("sm_playertimeforward", RunForwardCheck, ADMFLAG_KICK, "Run Playertime Forward and check for people that have not been on for timetrack_minimum_time in the last timetrack_threshold")
	RegAdminCmd("sm_playertimeprotect", Command_ProtectFromForward, ADMFLAG_KICK, "Give Player or SteamID protection from getting targeted by the Offline Forward.")
	RegAdminCmd("sm_playertimeunprotect", Command_UnprotectFromForward, ADMFLAG_KICK, "Remove Player or SteamID protection from getting targeted by the Offline Forward.")
	
	// load Config File
	if (FindConVar("playertimetracker_version") == INVALID_HANDLE) { AutoExecConfig(true); }
	CreateConVar("playertimetracker_version", PLUGIN_VERSION, "Playertime Tracker Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	// create Forwards
	forward_clientNotSeen = CreateGlobalForward("SteamIdFallsBelowMinimumOnlineTime", ET_Event, Param_String);
	
	if (GetConVarBool(g_enableForward)) {
		if (timer_forwardTimer == INVALID_HANDLE) {
			timer_forwardTimer = CreateTimer(86400.0, ForwardTimer, _, TIMER_REPEAT);
		}
	}
}

public OnMapStart()
{
	if (!GetConVarBool(g_enabled)) return;
	
	connectDB();
	InitializeDatabase();
	PrepareQuery(); // Do this OnMapStart rather than OnPluginStart because it loses connection to the DB OnMapEnd.
}

public OnMapEnd()
{
	if (!GetConVarBool(g_enabled)) return;
	
	if (db != INVALID_HANDLE) 						CloseHandle(db); // Same reason as above ^, close the handles since it loses connection to the DB
	if (db_PrepareStmtCheck != INVALID_HANDLE)		CloseHandle(db_PrepareStmtCheck);
	if (db_PrepareStmtForward != INVALID_HANDLE)	CloseHandle(db_PrepareStmtForward);
	if (db_PrepareStmtLog != INVALID_HANDLE)		CloseHandle(db_PrepareStmtLog);
	if (db_PrepareStmtLogread != INVALID_HANDLE)	CloseHandle(db_PrepareStmtLogread);
	if (db_PrepareStmtRead != INVALID_HANDLE)		CloseHandle(db_PrepareStmtRead);
	if (db_PrepareStmtUpdate != INVALID_HANDLE)		CloseHandle(db_PrepareStmtUpdate);
	if (db_PrepareStmtWrite != INVALID_HANDLE)		CloseHandle(db_PrepareStmtWrite);
	if (timer_forwardTimer != INVALID_HANDLE)		KillTimer(timer_forwardTimer);
}

public OnPluginEnd()
{
	if (!GetConVarBool(g_enabled)) return;
	
	if (db != INVALID_HANDLE) 						CloseHandle(db); // Not sure if OnMapEnd is called before OnPluginEnd, so this is here just in case.
	if (db_PrepareStmtCheck != INVALID_HANDLE)		CloseHandle(db_PrepareStmtCheck);
	if (db_PrepareStmtForward != INVALID_HANDLE)	CloseHandle(db_PrepareStmtForward);
	if (db_PrepareStmtLog != INVALID_HANDLE)		CloseHandle(db_PrepareStmtLog);
	if (db_PrepareStmtLogread != INVALID_HANDLE)	CloseHandle(db_PrepareStmtLogread);
	if (db_PrepareStmtRead != INVALID_HANDLE)		CloseHandle(db_PrepareStmtRead);
	if (db_PrepareStmtUpdate != INVALID_HANDLE)		CloseHandle(db_PrepareStmtUpdate);
	if (db_PrepareStmtWrite != INVALID_HANDLE)		CloseHandle(db_PrepareStmtWrite);
	if (timer_forwardTimer != INVALID_HANDLE)		KillTimer(timer_forwardTimer);	
}

public ForwardEnableChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) {
	if (StrEqual(newVal, "1", false)) {
		if (timer_forwardTimer == INVALID_HANDLE) { timer_forwardTimer = CreateTimer(86400.0, ForwardTimer, _, TIMER_REPEAT); }
	} else {
		if (timer_forwardTimer != INVALID_HANDLE) {
			KillTimer(timer_forwardTimer);
			timer_forwardTimer = INVALID_HANDLE;
		}
	}	
}

ForwardCheck() {
	decl String:buffer[256];
	new Handle:query = INVALID_HANDLE;
	query = SQL_Query(db, SteamidQuery, sizeof(SteamidQuery));
	if (query == INVALID_HANDLE) {
		new String:error[255];
		SQL_GetError(db, error, sizeof(error));
		PrintToServer("Failed to query database for SteamIDs (error: %s)", error);
		return -1
	} else {
		if(SQL_MoreRows(query)) {
			new time = 0;
			new users = 0;
			while(SQL_FetchRow(query)) {
				SQL_FetchString(query, 0, buffer, sizeof(buffer));
				SQL_BindParamString(db_PrepareStmtForward, 0, buffer, true);
				if(!SQL_Execute(db_PrepareStmtForward)) {
					decl String:Error[1024];
					SQL_GetError(db_PrepareStmtForward, Error, sizeof(Error));
					PrintToServer("An error has occured while querying the Database: %s", Error);
					return -1;
				}
				if(SQL_FetchRow(db_PrepareStmtForward)) {
					new isProtected = SQL_FetchInt(db_PrepareStmtForward, 0);
					new alreadyRan = SQL_FetchInt(db_PrepareStmtForward, 1);
					if(isProtected != 1) {
						if (alreadyRan != 1 || GetConVarBool(g_runForwardMultipleTimes)) {
							time = GetLastTwoWeeks(buffer);
							if(time < GetConVarInt(g_minTime)) {
								new Action:result = Plugin_Continue;
								Call_StartForward(forward_clientNotSeen);
								Call_PushString(buffer);
								Call_Finish(result);
								users = users + 1
								WriteToForwardConfig(buffer, _, 1);
							}
						}
					}
				} else {
					time = GetLastTwoWeeks(buffer);
					if(time < GetConVarInt(g_minTime)) {
						new Action:result = Plugin_Continue;
						Call_StartForward(forward_clientNotSeen);
						Call_PushString(buffer);
						Call_Finish(result);
						users = users + 1
						WriteToForwardConfig(buffer, _, 1);
					}
				}
			}
			return users;
		} else {
			return 0;
		}
	}
}

public Action:ForwardTimer(Handle:timer) {
	PrintToServer("Ran Forward on %i SteamIDs", ForwardCheck());
}

public Action:RunForwardCheck(client, args) {
	if(!CheckCommandAccess(client, "sm_playertimeforward", ADMFLAG_KICK)) {
		ReplyToCommand(client, "[SM] You do not have the Permission to use this command");
		return Plugin_Handled;
	}
	ReplyToCommand(client, "[SM] Forward ran on %i SteamIDs", ForwardCheck());
	return Plugin_Handled;
}

/* GetPlayerTime
 * Category: Console Command
 * 
 * Retrieve Player time from database
 * 
*/
public Action:GetPlayerTime(client, args) {
	if(!CheckCommandAccess(client, "sm_playertime", ADMFLAG_KICK)) {
		PrintToChat(client, "[SM] You do not have the Permission to use this command");
		return Plugin_Handled;
	}
	if(args < 1) {
		ReplyToCommand(client, "[SM] Wrong Syntax.\n[SM] Usage: sm_playertime <Username/STEAMID2>");
		return Plugin_Handled;
	} else {
		decl String:CommandsString[1024];
		GetCmdArgString(CommandsString, sizeof(CommandsString))
		decl String:explodedStrings[2][1024];
		ExplodeString(CommandsString, " ", explodedStrings, sizeof(explodedStrings), sizeof(explodedStrings[]))
		decl String:arg1[128];
		strcopy(arg1, sizeof(arg1), explodedStrings[0]);
		decl String:timeFormat[1024];
		GetConVarString(g_timeFormat, timeFormat, sizeof(timeFormat));
		new String:target_name[MAX_TARGET_LENGTH];
		new target_list[MAXPLAYERS], target_count;
		new bool:tn_is_ml;			
		decl String:steamID[256];
		new clientPlayTime = 0;
		if ((target_count = ProcessTargetString( arg1, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0) {
			SQL_BindParamString(db_PrepareStmtCheck, 0, arg1, true);
			if(!SQL_Execute(db_PrepareStmtCheck)) {
				decl String:Error[1024];
				SQL_GetError(db_PrepareStmtCheck, Error, sizeof(Error));
				PrintToServer("An error has occured while querying the Database: %s", Error);
				ReplyToCommand(client, "An error has occured while querying the Database: %s", Error);
				return Plugin_Handled;
			}
			if(SQL_FetchRow(db_PrepareStmtCheck)) {
				if(SQL_FetchInt(db_PrepareStmtCheck, 0) == 1) {
					SQL_BindParamString(db_PrepareStmtRead, 0, arg1, true);
					if(!SQL_Execute(db_PrepareStmtRead)) {
						decl String:Error[1024];
						SQL_GetError(db_PrepareStmtRead, Error, sizeof(Error));
						PrintToServer("An error has occured while querying the Database: %s", Error);
						ReplyToCommand(client, "An error has occured while querying the Database: %s", Error);
						return Plugin_Handled;
					}
					if(SQL_FetchRow(db_PrepareStmtRead)) {
						new getInt = SQL_FetchInt(db_PrepareStmtRead, 0);
						decl String:timeString[1024];
						GetTimeString(getInt, timeString, sizeof(timeString));
						ReplyToCommand(client, "[SM] SteamID %s has played for %s", arg1, timeString);
						return Plugin_Handled;
					}
				} else {
					ReplyToCommand(client, "[SM] No Data has been found in the database.");
					return Plugin_Handled;
				}
			} else {
				PrintToServer("An error has occured while fetching the Query Result");
				ReplyToCommand(client, "An error has occured while fetching the Query Result");
				return Plugin_Handled;
			}
			return Plugin_Handled;
		}
		decl String:clientName[1024];
		for (new i = 0; i < target_count; i++) {
			clientPlayTime =  RoundFloat(GetClientTime(target_list[i]));
			GetClientAuthString(target_list[i], steamID, sizeof(steamID));
			GetClientName(target_list[i], clientName, sizeof(clientName));
			SQL_BindParamString(db_PrepareStmtCheck, 0, steamID, true);
			if(!SQL_Execute(db_PrepareStmtCheck)) {
				decl String:Error[1024];
				SQL_GetError(db_PrepareStmtCheck, Error, sizeof(Error));
				PrintToServer("An error has occured while querying the Database: %s", Error);
				ReplyToCommand(client, "An error has occured while querying the Database: %s", Error);
			}
			if(SQL_FetchRow(db_PrepareStmtCheck)) {
				if(SQL_FetchInt(db_PrepareStmtCheck, 0) == 1) {
					SQL_BindParamString(db_PrepareStmtRead, 0, steamID, true);
					if(!SQL_Execute(db_PrepareStmtRead)) {
						decl String:Error[1024];
						SQL_GetError(db_PrepareStmtRead, Error, sizeof(Error));
						PrintToServer("An error has occured while querying the Database: %s", Error);
						ReplyToCommand(client, "An error has occured while querying the Database: %s", Error);
					}
					if(SQL_FetchRow(db_PrepareStmtRead)) {
						new getInt = SQL_FetchInt(db_PrepareStmtRead, 0);
						new newInt = getInt + clientPlayTime;
						decl String:timeString[1024];
						GetTimeString(newInt, timeString, sizeof(timeString), timeFormat);
						ReplyToCommand(client, "[SM] User %s has played for %s", clientName, timeString);
					}
				} else {
					decl String:timeString[1024];
					GetTimeString(clientPlayTime, timeString, sizeof(timeString), timeFormat);
					ReplyToCommand(client, "[SM] User %s has played for %s", clientName, timeString);
				}
			} else {
				PrintToServer("An error has occured while fetching the Query Result");
				ReplyToCommand(client, "An error has occured while fetching the Query Result");
			}
		}
	}
	return Plugin_Handled;
}

public Action:Command_ProtectFromForward(client, args) {
	if(!CheckCommandAccess(client, "sm_playertimeprotect", ADMFLAG_KICK)) {
		PrintToChat(client, "[SM] You do not have the Permission to use this command");
		return Plugin_Handled;
	}
	if(args < 1) {
		ReplyToCommand(client, "[SM] Wrong Syntax.\n[SM] Usage: sm_playertime <Username/STEAMID2>");
		return Plugin_Handled;
	} else {
		decl String:CommandsString[1024];
		GetCmdArgString(CommandsString, sizeof(CommandsString))
		decl String:explodedStrings[3][1024];
		ExplodeString(CommandsString, " ", explodedStrings, sizeof(explodedStrings), sizeof(explodedStrings[]))
		decl String:arg1[128];
		strcopy(arg1, sizeof(arg1), explodedStrings[0]);
		decl String:timeFormat[1024];
		GetConVarString(g_timeFormat, timeFormat, sizeof(timeFormat));
		new String:target_name[MAX_TARGET_LENGTH]; new target_list[MAXPLAYERS], target_count; new bool:tn_is_ml; decl String:steamID[256];
		if ((target_count = ProcessTargetString( arg1, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0) {
			WriteToForwardConfig(arg1, 1)
			ReplyToCommand(client, "[SM] Protected %s from forward", arg1);
			return Plugin_Handled;
		}
		decl String:clientName[1024];
		for (new i = 0; i < target_count; i++) {
			GetClientAuthString(client, steamID, sizeof(steamID));
			GetClientName(client, clientName, sizeof(clientName));
			WriteToForwardConfig(steamID, 1);
			ReplyToCommand(client, "[SM] Protected %s from forward", clientName);
		}
	}
	return Plugin_Handled;
}

public Action:Command_UnprotectFromForward(client, args) {
	if(!CheckCommandAccess(client, "sm_playertimeunprotect", ADMFLAG_KICK)) {
		PrintToChat(client, "[SM] You do not have the Permission to use this command");
		return Plugin_Handled;
	}
	if(args < 1) {
		ReplyToCommand(client, "[SM] Wrong Syntax.\n[SM] Usage: sm_playertime <Username/STEAMID2>");
		return Plugin_Handled;
	} else {
		decl String:CommandsString[1024];
		GetCmdArgString(CommandsString, sizeof(CommandsString))
		decl String:explodedStrings[3][1024];
		ExplodeString(CommandsString, " ", explodedStrings, sizeof(explodedStrings), sizeof(explodedStrings[]))
		decl String:arg1[128];
		strcopy(arg1, sizeof(arg1), explodedStrings[0]);
		decl String:timeFormat[1024];
		GetConVarString(g_timeFormat, timeFormat, sizeof(timeFormat));
		new String:target_name[MAX_TARGET_LENGTH]; new target_list[MAXPLAYERS], target_count; new bool:tn_is_ml; decl String:steamID[256];
		if ((target_count = ProcessTargetString( arg1, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0) {
			WriteToForwardConfig(arg1, 0)
			ReplyToCommand(client, "[SM] Unprotected %s from forward", arg1);
			return Plugin_Handled;
		}
		decl String:clientName[1024];
		for (new i = 0; i < target_count; i++) {
			GetClientAuthString(client, steamID, sizeof(steamID));
			GetClientName(client, clientName, sizeof(clientName));
			WriteToForwardConfig(steamID, 0);
			ReplyToCommand(client, "[SM] Unprotected %s from forward", clientName);
		}
	}
	return Plugin_Handled;
}

WriteToForwardConfig(const String:SteamID[], protected = -1, ran = -1) {
	decl String:EscapedString[2048];
	decl String:protectedString[128]; decl String:ranString[128];
	SQL_EscapeString(db, SteamID, EscapedString, sizeof(EscapedString));
	if (protected == -1) { strcopy(protectedString, sizeof(protectedString), "protected_from_forward"); }
	else { IntToString(protected, protectedString, sizeof(protectedString)); }
	if (ran == -1) { strcopy(ranString, sizeof(ranString), "already_ran_on"); }
	else { IntToString(ran, ranString, sizeof(ranString)); }
	decl String:queryString[2048];
	Format(queryString, sizeof(queryString), "UPDATE sm_playertimeforwards SET protected_from_forward = %s, already_ran_on = %s WHERE steamid = '%s'", protectedString, ranString, EscapedString)
	SQL_FastQuery(db, queryString);
	if(SQL_GetAffectedRows(db) < 1) {
		Format(queryString, sizeof(queryString), "INSERT INTO sm_playertimeforwards ( steamid, protected_from_forward, already_ran_on ) VALUES ('%s', %i, %i)", EscapedString, StringToInt(protectedString), StringToInt(ranString));
		SQL_FastQuery(db, queryString);
	}
}

/* GetPlayerTime2Weeks
 * Category: Console Command
 * 
 * Retrieve Player time of last 2 weeks from database
 * 
*/
public Action:GetPlayerTimeTwoWeeks(client, args) {
// There is no need for this check, sourcemod already does this when the player types the RegAdminCmd.
//	if(!CheckCommandAccess(client, "sm_playertimetimespan", ADMFLAG_KICK)) {
//		PrintToChat(client, "[SM] You do not have the Permission to use this command");
//		return Plugin_Handled;
//	}
	if(args < 1) {
		ReplyToCommand(client, "[SM] Wrong Syntax.\n[SM] Usage: sm_playertimetimespan <Username/STEAMID2>");
		return Plugin_Handled;
	} else {
		decl String:CommandsString[1024];
		GetCmdArgString(CommandsString, sizeof(CommandsString))
		decl String:explodedStrings[2][1024];
		ExplodeString(CommandsString, " ", explodedStrings, sizeof(explodedStrings), sizeof(explodedStrings[]))
		decl String:arg1[128];
		strcopy(arg1, sizeof(arg1), explodedStrings[0]);
		decl String:timeFormat[1024];
		GetConVarString(g_timeFormat, timeFormat, sizeof(timeFormat));
		new String:target_name[MAX_TARGET_LENGTH];
		new target_list[MAXPLAYERS], target_count;
		new bool:tn_is_ml;			
		decl String:steamID[256];
		new clientPlayTime = 0;
		if ((target_count = ProcessTargetString( arg1, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0) {
			SQL_BindParamString(db_PrepareStmtCheck, 0, arg1, true);
			if(!SQL_Execute(db_PrepareStmtCheck)) {
				decl String:Error[1024];
				SQL_GetError(db_PrepareStmtCheck, Error, sizeof(Error));
				PrintToServer("[PlayerTimeTracker] An error has occured while querying the Database: %s", Error);
				ReplyToCommand(client, "[SM] An error has occured while querying the Database: %s", Error);
				return Plugin_Handled;
			}
			if(SQL_FetchRow(db_PrepareStmtCheck)) {
				if(SQL_FetchInt(db_PrepareStmtCheck, 0) == 1) {
					new getInt = GetLastTwoWeeks(arg1);
					if (getInt < 0) {
						ReplyToCommand(client, "[SM] An error has occured while fetching Playertime. Check Serverconsole for more information.");
						return Plugin_Handled;
					} else {
						decl String:timeString[1024];
						GetTimeString(getInt, timeString, sizeof(timeString));
						ReplyToCommand(client, "[SM] SteamID %s has played for %s in the past 2 weeks", arg1, timeString);
						return Plugin_Handled;
					}
				} else {
					ReplyToCommand(client, "[SM] No Data has been found in the database.");
					return Plugin_Handled;
				}
			} else {
				PrintToServer("[PlayerTimeTracker] An error has occured while fetching the Query Result");
				ReplyToCommand(client, "[SM] An error has occured while fetching the Query Result");
				return Plugin_Handled;
			}
		}
		decl String:clientName[1024];
		for (new i = 0; i < target_count; i++) {
			clientPlayTime =  RoundFloat(GetClientTime(target_list[i]));
			GetClientAuthString(target_list[i], steamID, sizeof(steamID));
			GetClientName(target_list[i], clientName, sizeof(clientName));
			SQL_BindParamString(db_PrepareStmtCheck, 0, steamID, true);
			if(!SQL_Execute(db_PrepareStmtCheck)) {
				decl String:Error[1024];
				SQL_GetError(db_PrepareStmtCheck, Error, sizeof(Error));
				PrintToServer("[PlayerTimeTracker] An error has occured while querying the Database: %s", Error);
				ReplyToCommand(client, "[SM] An error has occured while querying the Database: %s", Error);
			}
			if(SQL_FetchRow(db_PrepareStmtCheck)) {
				if(SQL_FetchInt(db_PrepareStmtCheck, 0) == 1) {
					new getInt = GetLastTwoWeeks(steamID);
					if (getInt < 0) {
						ReplyToCommand(client, "[SM] An error has occured while fetching Playertime. Check Serverconsole for more information.");
						return Plugin_Handled;
					} else {
						decl String:timeString[1024];
						GetTimeString(getInt, timeString, sizeof(timeString));
						ReplyToCommand(client, "[SM] User %s has played for %s in the past 2 weeks.", clientName, timeString);
						return Plugin_Handled;
					}
				} else {
					decl String:timeString[1024];
					GetTimeString(clientPlayTime, timeString, sizeof(timeString), timeFormat);
					ReplyToCommand(client, "[SM] User %s has played for %s in the past 2 weeks.", clientName, timeString);
				}
			} else {
				PrintToServer("[PlayerTimeTracker] An error has occured while fetching the Query Result");
				ReplyToCommand(client, "[SM] An error has occured while fetching the Query Result");
			}
		}
	}
	return Plugin_Handled;
}

/* Client disconnects
 * Category: Plugin Callback
 * 
 * If a client disconnects, save their Online Time in the Database
 * 
*/
public OnClientDisconnect(client) {
	if (g_enabled && IsClientInGame(client) && !IsFakeClient(client)) writeToDB(client); // Have to run IsClientConnected or IsClientInGame BEFORE the IsFakeClient check or you'll get an index out of bounds.
}

GetLastTwoWeeks(const String:steamid[]) {
	new date = GetTime() - RoundFloat(60 * 60 * 24 * GetConVarFloat(g_threshold));
	SQL_BindParamString(db_PrepareStmtLogread, 0, steamid, true);
	SQL_BindParamInt(db_PrepareStmtLogread, 1, date, true);
	if(!SQL_Execute(db_PrepareStmtLogread)) {
		decl String:Error[1024];
		SQL_GetError(db_PrepareStmtLogread, Error, sizeof(Error));
		PrintToServer("[PlayerTimeTracker] An error has occured while querying the Database: %s", Error);
		return -1;
	}
	if(SQL_MoreRows(db_PrepareStmtLogread)) {
		new t = 0;
		while(SQL_FetchRow(db_PrepareStmtLogread)) { t = t + SQL_FetchInt(db_PrepareStmtLogread, 0); }
		return t;
	} else {
		return 0;
	}
}

GetTimeString(time, String:buffer[], length, const String:format[] = "%i:%02i:%02i:%02i") {
	new d_modulo = time % 86400;
	new d = (time - d_modulo ) / 86400;
	new h_modulo = d_modulo % 3600;
	new h = (d_modulo - h_modulo) / 3600;
	new m_modulo = d_modulo % 60;
	new m = (h_modulo - m_modulo) / 60;
	new s = m_modulo;
	Format(buffer, length, format, d, h, m, s);
}

bool:connectDB() {
	decl String:error[255];
	if (SQL_CheckConfig("PlayerTimeTracker")) {
		db = SQL_Connect("PlayerTimeTracker", true, error, sizeof(error));
	} else {
		db = SQL_Connect("default", true, error, sizeof(error));
	}

	if (db == INVALID_HANDLE) {
		PrintToServer("[PlayerTimeTracker] Could not connect to database \"default\": %s", error);
		return false;
	}
	return true;
}

bool:PrepareQuery() {
	decl String:error[255];

	if (db_PrepareStmtWrite == INVALID_HANDLE) {
		db_PrepareStmtWrite = SQL_PrepareQuery(db, WriteQuery, error, sizeof(error));
		if (db_PrepareStmtWrite == INVALID_HANDLE) {
			PrintToServer("[PlayerTimeTracker] Could not prepare write statement: %s", error);
			return false;
		}
	}
	if (db_PrepareStmtRead == INVALID_HANDLE) {
		db_PrepareStmtRead = SQL_PrepareQuery(db, ReadQuery, error, sizeof(error));
		if (db_PrepareStmtRead == INVALID_HANDLE) {
			PrintToServer("[PlayerTimeTracker] Could not prepare read statement: %s", error);
			return false;
		}
	}
	if (db_PrepareStmtCheck == INVALID_HANDLE) {
		db_PrepareStmtCheck = SQL_PrepareQuery(db, CheckQuery, error, sizeof(error));
		if (db_PrepareStmtCheck == INVALID_HANDLE) {
			PrintToServer("[PlayerTimeTracker] Could not prepare check statement: %s", error);
			return false;
		}
	}
	if (db_PrepareStmtUpdate == INVALID_HANDLE) {
		db_PrepareStmtUpdate = SQL_PrepareQuery(db, UpdateQuery, error, sizeof(error));
		if (db_PrepareStmtUpdate == INVALID_HANDLE) {
			PrintToServer("[PlayerTimeTracker] Could not prepare check statement: %s", error);
			return false;
		}
	}
	if (db_PrepareStmtLog == INVALID_HANDLE) {
		db_PrepareStmtLog = SQL_PrepareQuery(db, LogQuery, error, sizeof(error));
		if (db_PrepareStmtLog == INVALID_HANDLE) {
			PrintToServer("[PlayerTimeTracker] Could not prepare log statement: %s", error);
			return false;
		}
	}
	if (db_PrepareStmtLogread == INVALID_HANDLE) {
		db_PrepareStmtLogread = SQL_PrepareQuery(db, ReadlogQuery, error, sizeof(error));
		if (db_PrepareStmtLogread == INVALID_HANDLE) {
			PrintToServer("[PlayerTimeTracker] Could not prepare log statement: %s", error);
			return false;
		}
	}
	if (db_PrepareStmtForward == INVALID_HANDLE) {
		db_PrepareStmtForward = SQL_PrepareQuery(db, ForwardQuery, error, sizeof(error));
		if (db_PrepareStmtForward == INVALID_HANDLE) {
			PrintToServer("[PlayerTimeTracker] Could not prepare log statement: %s", error);
			return false;
		}
	}
	return true;
}

bool:InitializeDatabase() {
	decl String:buffer[256];
	SQL_ReadDriver(db, buffer, sizeof(buffer));
	if (!tableExists()) {
		PrintToServer("[PlayerTimeTracker] Creating Player Time Tracker Table")
		if (strcmp(buffer, "mysql") == 0) {
			SQL_FastQuery(db, init_mysql1, sizeof(init_mysql1));
			SQL_FastQuery(db, init_mysql2, sizeof(init_mysql2));
			SQL_FastQuery(db, init_mysql3, sizeof(init_mysql3));
		} else if (strcmp(buffer, "sqlite") == 0) {
			SQL_FastQuery(db, init_sqlite1, sizeof(init_sqlite1));
			SQL_FastQuery(db, init_sqlite2, sizeof(init_sqlite2));
			SQL_FastQuery(db, init_sqlite3, sizeof(init_sqlite3));
		} else {
			PrintToServer("[PlayerTimeTracker] Unknown driver type '%s', cannot create tables.", buffer);
		}
	}
}

bool:tableExists() {
	decl String:buffer[256];
	SQL_ReadDriver(db, buffer, sizeof(buffer));
	new Handle:query = INVALID_HANDLE;
	if (strcmp(buffer, "mysql") == 0) {
		query = SQL_Query(db, exists_mysql, sizeof(exists_mysql));
	} else if (strcmp(buffer, "sqlite") == 0) {
		query = SQL_Query(db, exists_sqlite, sizeof(exists_sqlite));
	} else {
		PrintToServer("[PlayerTimeTracker] Unknown driver type '%s', cannot check for tables.", buffer);
	}
	if (query == INVALID_HANDLE) {
		new String:error[255];
		SQL_GetError(db, error, sizeof(error));
		PrintToServer("[PlayerTimeTracker] Failed to query (error: %s)", error);
		return false
	} else {
		SQL_FetchRow(query)
		if (SQL_FetchInt(query, 0) == 1) {
			CloseHandle(query)
			return true;
		}
		CloseHandle(query)
		return false;
	}
}

writeToDB(client) {
	decl String:authid[256];
	new clientPlayTime = RoundFloat(GetClientTime(client));
	GetClientAuthString(client, authid, sizeof(authid));
	SQL_BindParamString(db_PrepareStmtLog, 0, authid, true);
	SQL_BindParamInt(db_PrepareStmtLog, 1, clientPlayTime, true);
	SQL_BindParamInt(db_PrepareStmtLog, 2, GetTime(), true);
	if(!SQL_Execute(db_PrepareStmtLog)) {
		decl String:Error[1024];
		SQL_GetError(db_PrepareStmtLog, Error, sizeof(Error));
		PrintToServer("[PlayerTimeTracker] An error has occured while querying the Database: %s", Error);
		return;
	}
	SQL_BindParamString(db_PrepareStmtCheck, 0, authid, true);
	if(!SQL_Execute(db_PrepareStmtCheck)) {
		decl String:Error[1024];
		SQL_GetError(db_PrepareStmtCheck, Error, sizeof(Error));
		PrintToServer("[PlayerTimeTracker] An error has occured while querying the Database: %s", Error);
		return;
	}
	
	if(SQL_FetchRow(db_PrepareStmtCheck)) {
		if(SQL_FetchInt(db_PrepareStmtCheck, 0) == 1) {
			SQL_BindParamString(db_PrepareStmtRead, 0, authid, true);
			if(!SQL_Execute(db_PrepareStmtRead)) {
				decl String:Error[1024];
				SQL_GetError(db_PrepareStmtRead, Error, sizeof(Error));
				PrintToServer("[PlayerTimeTracker] An error has occured while querying the Database: %s", Error);
				return;
			}
			if(SQL_FetchRow(db_PrepareStmtRead)) {
				new getInt = SQL_FetchInt(db_PrepareStmtRead, 0);
				new newInt = getInt + clientPlayTime;
				SQL_BindParamInt(db_PrepareStmtUpdate, 0, newInt, true);
				SQL_BindParamString(db_PrepareStmtUpdate, 1, authid, true);
				if(!SQL_Execute(db_PrepareStmtUpdate)) {
					decl String:Error[1024];
					SQL_GetError(db_PrepareStmtUpdate, Error, sizeof(Error));
					PrintToServer("[PlayerTimeTracker] An error has occured while querying the Database: %s", Error);
					return;
				}
				WriteToForwardConfig(authid);
			}
		} else {
			SQL_BindParamString(db_PrepareStmtWrite, 0, authid, true);
			SQL_BindParamInt(db_PrepareStmtWrite, 1, clientPlayTime, true);
			if(!SQL_Execute(db_PrepareStmtWrite)) {
				decl String:Error[1024];
				SQL_GetError(db_PrepareStmtWrite, Error, sizeof(Error));
				PrintToServer("[PlayerTimeTracker] An error has occured while writing to the Database: %s", Error);
			}
		}
	} else {
		PrintToServer("[PlayerTimeTracker] An error has occured while fetching the Query Result");
		return;
	}
}
