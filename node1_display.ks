//set displaySeparator to "+----------------------------------------+".
set infoOffset to 8.

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
		{ return "|               EXECUTE NODE             |". },
		{ return "+----------------------------------------+". },
		{ return "| PHASE:                                 |". },
		{ return "| NODE IN:                               |". },
		{ return "| DELTA V:                               |". },
		{ return "| BURN TIME:                             |". },
		{ return "+----------------------------------------+". }
	).
	__printLines(lines).
}

function updateDisplay {
	__clearDisplay().
	local lines to list(
		{ return "+----------------------------------------+". },
		{ return "|               EXECUTE NODE             |". },
		{ return "+----------------------------------------+". },
		{ return "| PHASE: " + state. },
		{ return "| NODE IN: " + round(nextnode:eta * 10) / 10 + " s". },
		{ return "| DELTA V: " + round(nextnode:deltav:mag * 10) / 10 + " m/s". },
		{ return "| BURN TIME: " + round(burnTime) + " s". },
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
