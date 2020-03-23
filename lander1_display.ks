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
		{ return "|           PROPULSIVE LANDER            |". },
		{ return "+----------------------------------------+". },
		{ return "| PHASE:                                 |". },
		{ return "| ALTITUDE:                              |". },
		{ return "| VELOCITY:                              |". },
		{ return "| DELTA V:                               |". },
		{ return "| TIME TO BURN:                          |". },
		{ return "+----------------------------------------+". }
	).
	__printLines(lines).
}

function updateDisplay {
	__clearDisplay().
	local lines to list(
		{ return "+----------------------------------------+". },
		{ return "|           PROPULSIVE LANDER            |". },
		{ return "+----------------------------------------+". },
		{ return "| PHASE: " + state. },
		{ return "| ALTITUDE: " + height + "m". },
		{ return "| VELOCITY: " + descentV. },
		{ return "| DELTA V: " + deltaV. },
		{ return "| TIME TO BURN: " + timeToBurn. },
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
