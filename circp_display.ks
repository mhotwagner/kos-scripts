set lineLength to 40.

run display_utils.

function updateDisplay {
	local parameter info is list().
	local keys to list(
		"PHASE",
		"PERI IN",
		"BURN IN",
		"BURN TIME",
		"DELTA V"
	).
	local values to list(
		state,
		round(eta:periapsis) + " s",
		round((eta:periapsis - (burnTime/2)) * 10) / 10 + " s",
		round(burnTime * 100) / 100 + " s",
		(round(deltaV*10)/10) + " m/s"
	).
	local title to "CIRCULARIZE AT APOAPSIS".
	__updateDisplay(keys, values, title, info, lineLength).
}