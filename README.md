# MultiDoggof *
*) Project name

Since it's hard to find good new LAN games anymore one must do it themselves. Inspired by WW2 aircraft carrier warfare, 5v5 MOBA gameplay and BattleBit's casual take on the milsim genre.

Initial locked in goals before adding major new ones:
- DONE Basic networking
- DONE Lobby
- DONE Teams
- DONE Spawning of players
- DONE Movement synced over network. (MOVED TO FUTURE TODO: Simplify movement)
- DONE Fog of war
- DONE Reconnaissance action
- DONE Visible ghosts of acquired information
- DONE Basic objectives
- DONE Attack action
- DONE Scorekeeping
- BUGGY Return to lobby
	on 2nd launch:
		1 ClientState checklist initialized w/ false for each client id.
		HOST started client state check timer, ready to receive = true
		HOST WAITING for clients ready to spawn, expected state: 1
		1 started pre_round_timer
		1944280710 called update_client_state 1 (waiting 4 spawn)
		1944280710 started pre_round_timer
		1944280710 got host confirmation for state update, received state == 1
		1944280710 got host confirmation for state update, fail timer stopped
		HOST checking clients states match? checklist: { 1944280710: <null> }
		client_state_check_timer_timeout
		HOST checking clients states match? checklist: { 1944280710: <null> }
		client_state_check_timer_timeout
		^^ repeating

bugs important to fix:
	- DONE postgame 2p only client gets both players' data and launches alone
	- DONE launch countdown in lobby needs to be interrupted on anyone's team change or hesitation
tweaks that feel important:
	- DONE mission effect area needs a visual cue (need to implement for attack as well)
	- DONE make some info available for the other team of an objective getting attacked
	- DONE randomized codenames for objectives

Phase 1.1: for the first playtest
- DONE Round timers
- DONE Resources (fuels,munitions)
- DONE Needs HUD as well

+ sound effects easier than getting visual clues of enemy attacks only in LoS?

Phase 2: Proper restructuring and cleanup of code
