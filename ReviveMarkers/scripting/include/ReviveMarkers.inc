/** Double-include prevention */
#if defined _revivemarkers_included_
  #endinput
#endif
#define _revivemarkers_included_
 
/**
 * Check if all condition are met by a client to spawn a Marker
 *
 * @param client  The client index you want check conditions (Int)
 * @return        True if Conditions are met, false if not
 * @errors			Invalid client index or client not connected
 */
native bool:CheckMarkerConditions(client);
 
/**
 * Checks if an entity is a marker
 *
 * @param marker  The entity you want to check (Int)
 * @return        True if it is a valid marker, false if entity invalid or not a valid Marker
 */
native bool:ValidMarker(entity);
 
/**
 * Spawns a marker at the Player's current position
 *
 * @param client  	The client index you want to spawn a marker for (Int)
 * @return        	True if Marker successfully spawned, false otherwise
 * @errors			Invalid client index or client not connected
 */
native bool:SpawnRMarker(client);
 
/**
 * Despawns the marker of a Player
 *
 * @param client  	The client index you want to despawn the marker (Int)
 * @return        	True if Marker successfully despawned, false otherwise
 * @errors			Invalid client index or client not connected
 */
native bool:DespawnRMarker(client);

/**
 * Set the maximum Number of possible revives. Overrides the value of the ConVar.
 * Set to -1 to disable Override and use ConVar Value again.
 *
 * @param maxPossibleRevives  The amount of revives that are possible (Int)
 * @return       			  True if setting override successfully
 * @errors					  maxPossibleRevives < -1
 */
native bool:SetReviveCount(maxPossibleRevives);

/**
 * Set the maximum Number of possible revives. Overrides the value of the ConVar.
 * Set to -1 to disable Override and use ConVar Value again.
 *
 * @param decayTime		Time before Marker will decay (Float)
 * @return       		True if setting override successfully
 * @errors				decayTime < -1
 */
native bool:setDecayTime(decayTime);

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
	MarkNativeAsOptional("SetDecayTime");
	MarkNativeAsOptional("SetReviveCount");
}
#endif