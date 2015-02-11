/* Copyright
 * Category: None
 * 
 * Easer Player Time Track by Wolvan
 * Contact: wolvan1@gmail.com
 * Big thanks to Mitchell & pheadxdll
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
new String:WriteQuery[] = "INSERT INTO sm_playertimetracker('authtype', 'identity', 'flags', 'immunity', 'name') VALUES('steam', ?, ?, ?, ?)";
new String:ReadQuery[] = "SELECT";
new String:CheckQuery[] = "SELECT EXISTS (SELECT * FROM sm_playertimetracker WHERE identity = ?)";
new String:init_mysql[] = "CREATE TABLE IF NOT EXISTS `sm_playertimetracker` (`id`  integer NOT NULL AUTO_INCREMENT, `steamid`  text NOT NULL, `time`  integer NOT NULL DEFAULT 0, PRIMARY KEY (`id`))"
new String:init_sqlite[] = 'CREATE TABLE "sm_playertimetracker" ("id"  INTEGER NOT NULL, "steamid"  TEXT NOT NULL, "time"  INTEGER NOT NULL DEFAULT 0)'
new String:exists_mysql[] = "SELECT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'sm_playertimetracker')"
new String:exists_sqlite[] = "SELECT count(*) FROM sqlite_master WHERE type='table' AND name='sm_playertimetracker'"
new Handle:db = INVALID_HANDLE;
new Handle:db_PrepareStmtRead = INVALID_HANDLE;
new Handle:db_PrepareStmtWrite = INVALID_HANDLE;
new Handle:db_PrepareStmtCheck = INVALID_HANDLE;

/* ConVar Handle creation
 * Category: Storage
 * 
 * Create the Variables to store the ConVar Handles in.
 * 
*/
new Handle:g_enabled = INVALID_HANDLE;

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
	g_disablePlugin = CreateConVar("timetrack_enabled", "1", "Enable Plugin Functionality", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	// register console commands
	RegConsoleCmd("sm_playertime", GetPlayerTime, "Get Playertime.")
	
	// load Config File
	if (FindConVar("playertimetracker_version") == INVALID_HANDLE) { AutoExecConfig(true); }
	
	CreateConVar("playertimetracker_version", PLUGIN_VERSION, "Playertime Tracker Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	PrepareQuery();
	InitializeDatabase();
}

/* GetPlayerTime
 * Category: Console Command
 * 
 * Retrieve Player time from database
 * 
*/
public Action:GetPlayerTime(client, args) {
	if(args < 1) {
		ReplyToCommand(client, "[SM] Wrong Syntax.\n[SM] Usage: sm_playertime <Username/STEAMID2>");
	} else {
		if(!hasAdminPermission(client)) {
			PrintToChat(client, "[SM] You do not have the Permission to use this command");
			return Plugin_Handled;
		}
		decl String:arg1[128];
		GetCmdArg(1, arg1, sizeof(arg1));
		
		new String:target_name[MAX_TARGET_LENGTH];
		new target_list[MAXPLAYERS], target_count;
		new bool:tn_is_ml;
		
		if ((target_count = ProcessTargetString( arg1, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0) {
			ReplyToTargetError(client, target_count);
			if (client != 0) {
				PrintToChat(client, "[SM] No targets found. Check console for more Information");
			}
			return Plugin_Handled;
		}
	 
		for (new i = 0; i < target_count; i++) {
			isOptOut[target_list[i]] = false;
			isOptOutByAdmin[target_list[i]] = false;
			PrintToChat(target_list[i], "[SM] You have been opted in to dropping ReviveMarkers by an Admin");
			SetOptState(target_list[i]);
		}
		if(client != 0) {
			PrintToChat(client, "[SM] Opted in %i Player(s)", target_count);
		} else {
			PrintToServer("[SM] Opted in %i Player(s)", target_count);
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
	// remove the marker
	despawnReviveMarker(client);
	
	// reset storage array values
	currentTeam[client] = 0;
	changingClass[client] = false;
	isOptOut[client] = false;
	isOptOutByAdmin[client] = false;
	reviveCount[client] = 0;
}

bool:PrepareQuery() {
	decl String:error[255];

	if (SQL_CheckConfig("PlayerTimeTracker")) {
		db = SQL_Connect("PlayerTimeTracker", true, error, sizeof(error));
	} else {
		db = SQL_Connect("default", true, error, sizeof(error));
	}

	if (db == INVALID_HANDLE) {
		PrintToServer("Could not connect to database \"default\": %s", error);
		return false;
	}
	if (db_PrepareStmtWrite == INVALID_HANDLE) {
		db_PrepareStmtWrite = SQL_PrepareQuery(db, WriteQuery, error, sizeof(error));
		PrintToServer("Could not prepare write statement: %s", error);
		if (db_PrepareStmtWrite == INVALID_HANDLE) {
			return false;
		}
	}
	if (db_PrepareStmtRead == INVALID_HANDLE) {
		db_PrepareStmtRead = SQL_PrepareQuery(db, ReadQuery, error, sizeof(error));
		PrintToServer("Could not prepare read statement: %s", error);
		if (db_PrepareStmtRead == INVALID_HANDLE) {
			return false;
		}
	}
	if (db_PrepareStmtCheck == INVALID_HANDLE) {
		db_PrepareStmtCheck = SQL_PrepareQuery(db, CheckQuery, error, sizeof(error));
		PrintToServer("Could not prepare check statement: %s", error);
		if (db_PrepareStmtCheck == INVALID_HANDLE) {
			return false;
		}
	}
	return true;
}

bool:InitializeDatabase() {
	decl String:buffer[256];
	SQL_ReadDriver(db, buffer, sizeof(buffer));
	
	if (strcmp(buffer, "mysql") == 0) {
		SQL_FastQuery(db, init_mysql, sizeof(init_mysql));
	} else if (strcmp(buffer, "sqlite") == 0) {
		SQL_FastQuery(db, init_sqlite, sizeof(init_sqlite));
	} else {
		PrintToServer("[SM] Unknown driver type '%s', cannot create tables.", buffer);
	}
}