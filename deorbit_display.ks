//set displaySeparator to "+----------------------------------------+".
declare parameter targetPeriapsis to 0.
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
		{ return  "+----------------------------------------+". },
		{ return  "|               DEORBITER                |". },
		{ return  "+----------------------------------------+". },
		{ return  "| SHIP:                                  |". },
		{ return  "| PHASE:                                 |". },
		{ return  "| PERIAPSIS:                             |". },
		{ return  "| TARGET:                                |". },
		{ return  "+----------------------------------------+". }
	).
	__printLines(lines).
}

function updateDisplay {
	local lines to list(
		{ return  "+----------------------------------------+". },
		{ return  "|               DEORBITER                |". },
		{ return  "+----------------------------------------+". },
		{ return  "| SHIP: " + ship:name. },
		{ return  "| PHASE: " + state. },
		{ return  "| PERIAPSIS: " + ship:periapsis. },
		{ return  "| TARGET: " + targetPeriapsis. },
		{ return  "+----------------------------------------+". }
	).
	__clearDisplay(). __printLines(lines).
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
	__clearInfo(). __printLines(lines, infoOffset).
}
