run display_utils.

function updateDisplay {
	local parameter info is "".
	local title to "PROPULSIVE LANDER".
	local keys to list(
		"PHASE",
		"VERTICAL VELOCITY",
		"CURRENT ALTITUDE",
		"SURFACE ALT",
		"BURN ALT",
		"BURN DELTA-V",
		"TIME TO BURN"
	).
	local values to list(
		 state,
		 descentV,
		 shipAlt,
		 surfaceAlt,
		 burnAlt,
		 impactv(surfaceAlt),
		 timeToBurn
	).
	__updateDisplay(keys, values, title, info, 40).
}
