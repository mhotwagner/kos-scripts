//set displaySeparator to "+----------------------------------------+".
set infoOffset to 9.

function __printLines {
	local parameter lines.
	local parameter offset is 0.
	from { local i to 0. }
	until i = lines:length
	step { set i to i + 1. }
	do { print lines[i]() at (0, i + offset). }
}

function __clearDisplay {
	local lines to list(
		{ return "+----------------------------------------+". },
		{ return "|              CIRCULARIZE               |". },
		{ return "+----------------------------------------+". },
		{ return "| PHASE:                                 |". },
		{ return "| APO IN:                                |". },
		{ return "| BURN IN:                               |". },
		{ return "| BURN TIME:                             |". },
		{ return "| DELTA V:                               |". },
		{ return "+----------------------------------------+". }
	).
	__printLines(lines).
}

function updateDisplay {
	__clearDisplay().
	local lines to list(
		{ return "+----------------------------------------+". },
		{ return "|              CIRCULARIZE               |". },
		{ return "+----------------------------------------+". },
		{ return "| PHASE: " + state. },
		{ return "| APO IN: " + round(eta:apoapsis) + " s". },
		{ return "| BURN IN: " + round((eta:apoapsis - (burnTime/2)) * 10) / 10 + " s". },
		{ return "| BURN TIME: " + round(burnTime * 100) / 100 + " s". },
		{ return "| DELTA V: " + (round(deltaV*10)/10) + " m/s". },
		{ return "+----------------------------------------+". }
	).
	__printLines(lines).
}

function __clearInfo {
	local lines to list(
		{ return "| INFO:                                  |". },
		{ return "+----------------------------------------+". }
	).
	__printLines(lines, infoOffset).
}

function updateInfo {
	local parameter message is "".
	set lines to list(
		{ return "| INFO: " + message. },
		{ return "+----------------------------------------+". }
	).
	__clearInfo().
	__printLines(lines, infoOffset).
}
