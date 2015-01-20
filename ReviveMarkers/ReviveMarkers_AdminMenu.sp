public AttachAdminMenu() {
	new TopMenuObject:player_commands = FindTopMenuCategory(hAdminMenu, ADMINMENU_PLAYERCOMMANDS);
 
	if (player_commands == INVALID_TOPMENUOBJECT) { return; }
 
	AddToTopMenu(hAdminMenu, "revivemarkers_no_markers_without_medic", TopMenuObject_Item, AdminMenu_NoMarkersWithoutMedic, obj_rmcommands, "revivemarkers_no_markers_without_medic", ADMFLAG_SLAY);
	AddToTopMenu(hAdminMenu, "revivemarkers_max_revives", TopMenuObject_Item, AdminMenu_MaxRevives, obj_rmcommands, "revivemarkers_max_revives", ADMFLAG_SLAY);
	AddToTopMenu(hAdminMenu, "revivemarkers_disable", TopMenuObject_Item, AdminMenu_Disable, obj_rmcommands, "revivemarkers_disable", ADMFLAG_SLAY);
	AddToTopMenu(hAdminMenu, "revivemarkers_admin_only", TopMenuObject_Item, AdminMenu_AdminOnly, obj_rmcommands, "revivemarkers_admin_only", ADMFLAG_SLAY);
	AddToTopMenu(hAdminMenu, "revivemarkers_drop_for_one_team", TopMenuObject_Item, AdminMenu_DropForOneTeam, obj_rmcommands, "revivemarkers_drop_for_one_team", ADMFLAG_SLAY);
	AddToTopMenu(hAdminMenu, "revivemarkers_decay_time", TopMenuObject_Item, AdminMenu_DecayTime, obj_rmcommands, "revivemarkers_decay_time", ADMFLAG_SLAY);
	AddToTopMenu(hAdminMenu, "revivemarkers_visible_for_medics", TopMenuObject_Item, AdminMenu_VisibleForMedics, obj_rmcommands, "revivemarkers_visible_for_medics", ADMFLAG_SLAY);
	AddToTopMenu(hAdminMenu, "revivemarkers_optout", TopMenuObject_Item, AdminMenu_OptOut, obj_rmcommands, "revivemarkers_optout", ADMFLAG_SLAY);
	AddToTopMenu(hAdminMenu, "revivemarkers_optin", TopMenuObject_Item, AdminMenu_OptIn, obj_rmcommands, "revivemarkers_optin", ADMFLAG_SLAY);
	if (VSHEnabled()) { AddToTopMenu(hAdminMenu, "revivemarkers_show_markers_for_hale", TopMenuObject_Item, AdminMenu_SaxtonHaleSeesItAll, obj_rmcommands, "revivemarkers_show_markers_for_hale", ADMFLAG_SLAY); }
}

/* No Markers without Medics
 * Category: AdminMenu Item
 * 
 * Creates a Menu Item for the ReviveMarkers Sub-Menu
 * 
*/
public AdminMenu_NoMarkersWithoutMedic(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength) {
	if (action == TopMenuAction_DisplayOption) {
		Format(buffer, maxlength, "Markers drop without medics");
	} else if (action == TopMenuAction_SelectOption) {
		DisplayMenu_NoMarkersWithoutMedic(param,topmenu);
	}
}
DisplayMenu_NoMarkersWithoutMedic(client, Handle:topmenu) {
	tmpTopMenuHandle = topmenu;
	new Handle:menu = CreateMenu(MenuHandler_NoMarkersWithoutMedic);
	SetMenuTitle(menu, "Will Markers drop without medics?");
	AddMenuItem(menu, "0", "Yes");
	AddMenuItem(menu, "1", "No");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}
public MenuHandler_NoMarkersWithoutMedic(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_Select) {
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		SetConVarInt(g_noMarkersWithoutMedics, StringToInt(info));
		RedisplayAdminMenu(tmpTopMenuHandle, param1);
	} else if (action == MenuAction_End) {
		CloseHandle(menu);
		if(tmpTopMenuHandle != INVALID_HANDLE) {
			CloseHandle(tmpTopMenuHandle);
			tmpTopMenuHandle = INVALID_HANDLE;
		}
	}
}

/* Max Revives
 * Category: AdminMenu Item
 * 
 * Creates a Menu Item for the ReviveMarkers Sub-Menu
 * 
*/
public AdminMenu_MaxRevives(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength) {
	if (action == TopMenuAction_DisplayOption) {
		Format(buffer, maxlength, "Max number of revives");
	} else if (action == TopMenuAction_SelectOption) {
		DisplayMenu_MaxRevives(param,topmenu);
	}
}
DisplayMenu_MaxRevives(client, Handle:topmenu) {
	tmpTopMenuHandle = topmenu;
	new Handle:menu = CreateMenu(MenuHandler_MaxRevives);
	SetMenuTitle(menu, "Max number of revives per round:");
	AddMenuItem(menu, "0", "Disable");
	AddMenuItem(menu, "1", "1");
	AddMenuItem(menu, "2", "2");
	AddMenuItem(menu, "3", "3");
	AddMenuItem(menu, "4", "4");
	AddMenuItem(menu, "5", "5");
	AddMenuItem(menu, "10", "10");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}
public MenuHandler_MaxRevives(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_Select) {
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		SetConVarInt(g_maxReviveMarkerRevives, StringToInt(info));
		RedisplayAdminMenu(tmpTopMenuHandle, param1);
	} else if (action == MenuAction_End) {
		CloseHandle(menu);
		if(tmpTopMenuHandle != INVALID_HANDLE) {
			CloseHandle(tmpTopMenuHandle);
			tmpTopMenuHandle = INVALID_HANDLE;
		}
	}
}

/* Disable Plugin
 * Category: AdminMenu Item
 * 
 * Creates a Menu Item for the ReviveMarkers Sub-Menu
 * 
*/
public AdminMenu_Disable(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength) {
	if (action == TopMenuAction_DisplayOption) {
		Format(buffer, maxlength, "Plugin enabled");
	} else if (action == TopMenuAction_SelectOption) {
		DisplayMenu_Disable(param,topmenu);
	}
}
DisplayMenu_Disable(client, Handle:topmenu) {
	tmpTopMenuHandle = topmenu;
	new Handle:menu = CreateMenu(MenuHandler_Disable);
	SetMenuTitle(menu, "Is plugin enabled?");
	AddMenuItem(menu, "0", "Yes");
	AddMenuItem(menu, "1", "No");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}
public MenuHandler_Disable(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_Select) {
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		SetConVarInt(g_disablePlugin, StringToInt(info));
		RedisplayAdminMenu(tmpTopMenuHandle, param1);
	} else if (action == MenuAction_End) {
		CloseHandle(menu);
		if(tmpTopMenuHandle != INVALID_HANDLE) {
			CloseHandle(tmpTopMenuHandle);
			tmpTopMenuHandle = INVALID_HANDLE;
		}
	}
}

/* Admin-Only Mode
 * Category: AdminMenu Item
 * 
 * Creates a Menu Item for the ReviveMarkers Sub-Menu
 * 
*/
public AdminMenu_AdminOnly(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength) {
	if (action == TopMenuAction_DisplayOption) {
		Format(buffer, maxlength, "Admin-Only Mode");
	} else if (action == TopMenuAction_SelectOption) {
		DisplayMenu_AdminOnly(param,topmenu);
	}
}
DisplayMenu_AdminOnly(client, Handle:topmenu) {
	tmpTopMenuHandle = topmenu;
	new Handle:menu = CreateMenu(MenuHandler_AdminOnly);
	SetMenuTitle(menu, "Admin-Only Usage:");
	AddMenuItem(menu, "0", "No");
	AddMenuItem(menu, "1", "Yes");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}
public MenuHandler_AdminOnly(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_Select) {
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		SetConVarInt(g_adminOnly, StringToInt(info));
		RedisplayAdminMenu(tmpTopMenuHandle, param1);
	} else if (action == MenuAction_End) {
		CloseHandle(menu);
		if(tmpTopMenuHandle != INVALID_HANDLE) {
			CloseHandle(tmpTopMenuHandle);
			tmpTopMenuHandle = INVALID_HANDLE;
		}
	}
}

/* Drop for one team only
 * Category: AdminMenu Item
 * 
 * Creates a Menu Item for the ReviveMarkers Sub-Menu
 * 
*/
public AdminMenu_DropForOneTeam(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength) {
	if (action == TopMenuAction_DisplayOption) {
		Format(buffer, maxlength, "Drop for one team only");
	} else if (action == TopMenuAction_SelectOption) {
		DisplayMenu_DropForOneTeam(param,topmenu);
	}
}
DisplayMenu_DropForOneTeam(client, Handle:topmenu) {
	tmpTopMenuHandle = topmenu;
	new Handle:menu = CreateMenu(MenuHandler_DropForOneTeam);
	SetMenuTitle(menu, "Drop for which team?");
	AddMenuItem(menu, "0", "Both");
	AddMenuItem(menu, "1", "RED");
	AddMenuItem(menu, "2", "BLU");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}
public MenuHandler_DropForOneTeam(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_Select) {
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		SetConVarInt(g_oneTeamOnly, StringToInt(info));
		RedisplayAdminMenu(tmpTopMenuHandle, param1);
	} else if (action == MenuAction_End) {
		CloseHandle(menu);
		if(tmpTopMenuHandle != INVALID_HANDLE) {
			CloseHandle(tmpTopMenuHandle);
			tmpTopMenuHandle = INVALID_HANDLE;
		}
	}
}

/* Marker decay time
 * Category: AdminMenu Item
 * 
 * Creates a Menu Item for the ReviveMarkers Sub-Menu
 * 
*/
public AdminMenu_DecayTime(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength) {
	if (action == TopMenuAction_DisplayOption) {
		Format(buffer, maxlength, "Marker decay time");
	} else if (action == TopMenuAction_SelectOption) {
		DisplayMenu_DecayTime(param,topmenu);
	}
}
DisplayMenu_MaxRevives(client, Handle:topmenu) {
	tmpTopMenuHandle = topmenu;
	new Handle:menu = CreateMenu(MenuHandler_DecayTime);
	SetMenuTitle(menu, "How long before the Marker despawns?");
	AddMenuItem(menu, "10.0", "10 seconds");
	AddMenuItem(menu, "11.0", "11 seconds");
	AddMenuItem(menu, "12.0", "12 seconds");
	AddMenuItem(menu, "13.0", "13 seconds");
	AddMenuItem(menu, "14.0", "14 seconds");
	AddMenuItem(menu, "15.0", "15 seconds");
	AddMenuItem(menu, "20.0", "20 seconds");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}
public MenuHandler_DecayTime(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_Select) {
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		SetConVarInt(g_decayTime, StringToFloat(info));
		RedisplayAdminMenu(tmpTopMenuHandle, param1);
	} else if (action == MenuAction_End) {
		CloseHandle(menu);
		if(tmpTopMenuHandle != INVALID_HANDLE) {
			CloseHandle(tmpTopMenuHandle);
			tmpTopMenuHandle = INVALID_HANDLE;
		}
	}
}

/* Only medics can see Markers
 * Category: AdminMenu Item
 * 
 * Creates a Menu Item for the ReviveMarkers Sub-Menu
 * 
*/
public AdminMenu_VisibleForMedics(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength) {
	if (action == TopMenuAction_DisplayOption) {
		Format(buffer, maxlength, "Markers only visible for medics");
	} else if (action == TopMenuAction_SelectOption) {
		DisplayMenu_VisibleForMedics(param,topmenu);
	}
}
DisplayMenu_VisibleForMedics(client, Handle:topmenu) {
	tmpTopMenuHandle = topmenu;
	new Handle:menu = CreateMenu(MenuHandler_VisibleForMedics);
	SetMenuTitle(menu, "Who can see Markers?");
	AddMenuItem(menu, "0", "Everyone");
	AddMenuItem(menu, "1", "Only Medics");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}
public MenuHandler_VisibleForMedics(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_Select) {
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		SetConVarInt(g_markerOnlySeenByMedics, StringToInt(info));
		RedisplayAdminMenu(tmpTopMenuHandle, param1);
	} else if (action == MenuAction_End) {
		CloseHandle(menu);
		if(tmpTopMenuHandle != INVALID_HANDLE) {
			CloseHandle(tmpTopMenuHandle);
			tmpTopMenuHandle = INVALID_HANDLE;
		}
	}
}

/* Markers visible for Saxton Hale
 * Category: AdminMenu Item
 * 
 * Creates a Menu Item for the ReviveMarkers Sub-Menu
 * 
*/
public AdminMenu_SaxtonHaleSeesItAll(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength) {
	if (action == TopMenuAction_DisplayOption) {
		Format(buffer, maxlength, "Saxton Hale can see Markers");
	} else if (action == TopMenuAction_SelectOption) {
		DisplayMenu_SaxtonHaleSeesItAll(param,topmenu);
	}
}
DisplayMenu_SaxtonHaleSeesItAll(client, Handle:topmenu) {
	tmpTopMenuHandle = topmenu;
	new Handle:menu = CreateMenu(MenuHandler_SaxtonHaleSeesItAll);
	SetMenuTitle(menu, "Show Markers to current Boss");
	AddMenuItem(menu, "1", "Yes");
	AddMenuItem(menu, "0", "No");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}
public MenuHandler_SaxtonHaleSeesItAll(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_Select) {
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		SetConVarInt(g_vshShowMarkers, StringToInt(info));
		RedisplayAdminMenu(tmpTopMenuHandle, param1);
	} else if (action == MenuAction_End) {
		CloseHandle(menu);
		if(tmpTopMenuHandle != INVALID_HANDLE) {
			CloseHandle(tmpTopMenuHandle);
			tmpTopMenuHandle = INVALID_HANDLE;
		}
	}
}

/* Opt Out Admin-Menu
 * Category: AdminMenu Item
 * 
 * Opt Other Players out
 * 
*/
public AdminMenu_OptOut(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength) {
	if (action == TopMenuAction_DisplayOption) {
		Format(buffer, maxlength, "Opt Out");
	} else if (action == TopMenuAction_SelectOption) {
		DisplayMenu_OptOut(param,topmenu);
	}
}
DisplayMenu_OptOut(client, Handle:topmenu) {
	new Handle:menu = CreateMenu(MenuHandler_OptOut);
	SetMenuTitle(menu, "Opt Players out");
	
	AddMenuItem(menu, "@all", "Everyone");
	AddMenuItem(menu, "@bots", "Bots");
	AddMenuItem(menu, "@alive", "Alive Players");
	AddMenuItem(menu, "@dead", "Dead Players");
	AddMenuItem(menu, "@humans", "Non-Bots (Humans)");
	AddMenuItem(menu, "@aim", "Aim");
	AddMenuItem(menu, "@me", "Me");
	AddMenuItem(menu, "@!me", "Everyone but me");
	AddMenuItem(menu, "@red", "Red Team Members");
	AddMenuItem(menu, "@blue", "Blue Team Members");
	
	decl String:nameBuffer[128];
	for (new i=1; i<=MaxClients; i++) {
		if (IsClientInGame(i)) {			
			GetClientName(i, nameBuffer, sizeof(nameBuffer));
			AddMenuItem(menu, nameBuffer, nameBuffer);
		}
	}
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}
public MenuHandler_OptOut(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_Select) {
		decl String:info[128];
		GetMenuItem(menu, param2, info, sizeof(info));
		FakeClientCommand(client, "revivemarkers_optout %s", info);
		RedisplayAdminMenu(menu, param1);
	} else if (action == MenuAction_End) {
		CloseHandle(menu);
	}
}

/* Opt In Admin-Menu
 * Category: AdminMenu Item
 * 
 * Opt Other Players in
 * 
*/
public AdminMenu_OptIn(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength) {
	if (action == TopMenuAction_DisplayOption) {
		Format(buffer, maxlength, "Opt In");
	} else if (action == TopMenuAction_SelectOption) {
		DisplayMenu_OptIn(param,topmenu);
	}
}
DisplayMenu_OptIn(client, Handle:topmenu) {
	new Handle:menu = CreateMenu(MenuHandler_OptIn);
	SetMenuTitle(menu, "Opt Players in");
	
	AddMenuItem(menu, "@all", "Everyone");
	AddMenuItem(menu, "@bots", "Bots");
	AddMenuItem(menu, "@alive", "Alive Players");
	AddMenuItem(menu, "@dead", "Dead Players");
	AddMenuItem(menu, "@humans", "Non-Bots (Humans)");
	AddMenuItem(menu, "@aim", "Aim");
	AddMenuItem(menu, "@me", "Me");
	AddMenuItem(menu, "@!me", "Everyone but me");
	AddMenuItem(menu, "@red", "Red Team Members");
	AddMenuItem(menu, "@blue", "Blue Team Members");
	
	decl String:nameBuffer[128];
	for (new i=1; i<=MaxClients; i++) {
		if (IsClientInGame(i)) {			
			GetClientName(i, nameBuffer, sizeof(nameBuffer));
			AddMenuItem(menu, nameBuffer, nameBuffer);
		}
	}
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}
public MenuHandler_OptIn(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_Select) {
		decl String:info[128];
		GetMenuItem(menu, param2, info, sizeof(info));
		FakeClientCommand(client, "revivemarkers_optin %s", info);
		RedisplayAdminMenu(menu, param1);
	} else if (action == MenuAction_End) {
		CloseHandle(menu);
	}
}