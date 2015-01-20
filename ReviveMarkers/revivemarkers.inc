/** Double-include prevention */
#if defined _revivemarkers_included_
  #endinput
#endif
#define _revivemarkers_included_
 
/**
 * Check if all condition are met by a client to spawn a Marker
 *
 * @param client  The client index you want check conditions
 * @return        True if Conditions are met, false if not
 * @errors			Invalid client index or client not connected
 */
native bool:CheckMarkerConditions(client);
 
/**
 * Checks if an entity is a marker
 *
 * @param marker  The entity you want to check
 * @return        True if it is a valid marker, false if entity invalid or not a valid Marker
 */
native bool:ValidMarker(entity);
 
/**
 * Spawns a marker at the Player's current position
 *
 * @param client  The client index you want to spawn a marker for
 * @return        True if Marker successfully spawned, false otherwise
 * @errors			Invalid client index or client not connected
 */
native bool:SpawnRMarker(client);
 
/**
 * Despawns the marker of a Player
 *
 * @param client  The client index you want to despawn the marker
 * @return        True if Marker successfully despawned, false otherwise
 * @errors			Invalid client index or client not connected
 */
native bool:DespawnRMarker(client);

public SharedPlugin:__pl_ReviveMarkers = {
	name = "revivemarkers",
	file = "ReviveMarkers.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};
 
#if !defined REQUIRE_PLUGIN
public __pl_ReviveMarkers_SetNTVOptional() {
	MarkNativeAsOptional("CheckMarkerConditions");
	MarkNativeAsOptional("ValidMarker");
	MarkNativeAsOptional("SpawnRMarker");
	MarkNativeAsOptional("DespawnRMarker");
}
#endif