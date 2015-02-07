#include <sourcemod>
#include <store>

#define PLUGIN_NAME "ReviveMarkers Store Integration"
#define PLUGIN_VERSION "1.0"
#define PLUGIN_AUTHOR "Wolvan"
#define PLUGIN_DESCRIPTION "Allow ReviveMarker Dropping to be purchased as a store upgrade."
#define PLUGIN_URL "https://forums.alliedmods.net/showthread.php?t=244208"

#define ITEMNAME "revivemarkers"

new bool:ReviveMarkersLoaded = false;
new bool:StoreLoaded = false;
new bool:hasItem[MAXPLAYERS+1] = { false, ... };
new Handle:recacheTimer = INVALID_HANDLE;
new Handle:g_recacheTime = INVALID_HANDLE;

public Plugin:myinfo = {
	name 			= PLUGIN_NAME,
	author 			= PLUGIN_AUTHOR,
	description 	= PLUGIN_DESCRIPTION,
	version 		= PLUGIN_VERSION,
	url 			= PLUGIN_URL
}

public OnPluginStart() {
	RegisterType();
	CacheItems(INVALID_HANDLE);
	g_recacheTime = CreateConVar("rmakersstore_recacheTime", "15.0", "ReviveMarkersStore: Time between Item Cache Refreshes", FCVAR_NOTIFY, true, 0.1);
	CreateConVar("rmakersstore_version", PLUGIN_VERSION, "ReviveMarkersStore Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	HookConVarChange(g_recacheTime, RefreshTimeChanged);
	recacheTimer = CreateTimer(GetConVarFloat(g_recacheTime), CacheItems, _, TIMER_REPEAT);
	RegAdminCmd("sm_rms_refresh_cache", refreshCache, ADMFLAG_KICK, "Refresh the item cache of Revivemarkers Store Integration manually.");
	RegAdminCmd("sm_rms_disable_refresh", disableRefresh, ADMFLAG_KICK, "Disable Automatic cache refresh of Revivemarkers Store Integration.");
	RegAdminCmd("sm_rms_enable_refresh", enableRefresh, ADMFLAG_KICK, "Enable Automatic cache refresh of Revivemarkers Store Integration.");
}

public Action:refreshCache(client, args) {
	CacheItems(INVALID_HANDLE);
	ReplyToCommand(client, "[SM] Revivemarkers Store Integration Cache refreshed.");
}

public Action:disableRefresh(client, args) {
	if (recacheTimer != INVALID_HANDLE) {
		KillTimer(recacheTimer);
		recacheTimer = INVALID_HANDLE;
		ReplyToCommand(client, "[SM] Revivemarkers Store Integration automatic cache refresh disabled.");
	} else {
		ReplyToCommand(client, "[SM] Revivemarkers Store Integration automatic cache refresh is already disabled.");
	}
}

public Action:enableRefresh(client, args) {
	if (recacheTimer != INVALID_HANDLE) {
		ReplyToCommand(client, "[SM] Revivemarkers Store Integration automatic cache refresh is already enabled.");
	} else {
		recacheTimer = CreateTimer(GetConVarFloat(g_recacheTime), CacheItems, _, TIMER_REPEAT);
		ReplyToCommand(client, "[SM] Revivemarkers Store Integration automatic cache refresh enabled.");
	}
}

public RefreshTimeChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) {
	if (recacheTimer != INVALID_HANDLE) {
		KillTimer(recacheTimer);
		CacheItems(INVALID_HANDLE);
		recacheTimer = CreateTimer(GetConVarFloat(g_recacheTime), CacheItems, _, TIMER_REPEAT);
	}
}

public OnPluginEnd() {
	if (recacheTimer != INVALID_HANDLE) {
		KillTimer(recacheTimer);
		recacheTimer = INVALID_HANDLE;
	}
}

public OnClientDisconnect(client) {
	hasItem[client] = false;
}

public OnClientConnected(client) {
	if (!IsClientInGame(client) || IsFakeClient(client)) { return; }
	new Handle:filter = CreateTrie();
	Store_GetUserItems(filter, Store_GetClientAccountID(client), Store_GetClientLoadout(client),  GetUserItemsCallback, client);
}

public OnAllPluginsLoaded() {
	ReviveMarkersLoaded = LibraryExists("revivemarkers");
	StoreLoaded = LibraryExists("store");
}
 
public OnLibraryRemoved(const String:name[]) {
	if (StrEqual(name, "revivemarkers")) {
		ReviveMarkersLoaded = false;
	} else if (StrEqual(name, "store")) {
		StoreLoaded = false;
	}
}
 
public OnLibraryAdded(const String:name[]) {
	if (StrEqual(name, "revivemarkers")) {
		ReviveMarkersLoaded = true;
	}else if (StrEqual(name, "store")) {
		StoreLoaded = true;
	} else if (StrEqual(name, "store-inventory")) {
		RegisterType();
	} else if (StrEqual(name, "store-backend")) {
		CacheItems(INVALID_HANDLE);
	}
}

public GetUserItemsCallback(items[], bool:equipped[], itemCount[], count, loadoutId, any:data) {
	for (new item = 0; item < count; item++) {
		decl String:name[32];
		Store_GetItemName(items[item], name, sizeof(name));
		if (StrEqual(name, ITEMNAME)) {
			hasItem[data] = true;
			return;
		}
	}
	hasItem[data] = false;
}

RegisterType() {
	if (LibraryExists("store-inventory")) { Store_RegisterItemType("wolvan_revivemarkers", OnItemUse); }
}
public Action:CacheItems(Handle:timer) {
	new Handle:filter = CreateTrie();
	for (new i = 1; i <= MaxClients; i++) {
		if (!IsClientInGame(i) || IsFakeClient(i)) { continue; }
		Store_GetUserItems(filter, Store_GetClientAccountID(i), Store_GetClientLoadout(i),  GetUserItemsCallback, i);
	}
}

public Store_ItemUseAction:OnItemUse(client, itemId, bool:equipped) {
	if ((client > 0) && (client < (MAXPLAYERS+1))) {
		PrintToChat(client, "[SM] It is enough to have this in your inventory.")
	}
	return Store_DoNothing;
}

public Action:OnReviveMarkerSpawn(client, marker) {
	if (!ReviveMarkersLoaded || !StoreLoaded) { return Plugin_Continue; }
	if (hasItem[client]) { return Plugin_Continue; }
	return Plugin_Stop;
}