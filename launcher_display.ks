//set displaySeparator to "+----------------------------------------+".
set infoOffset to 12.

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
		{ return  "|                LAUNCHER                |". },
		{ return  "+----------------------------------------+". },
		{ return  "| SHIP:                                  |". },
		{ return  "| PHASE:                                 |". },
		{ return  "| PIITCH:                                |". },
		{ return  "| VELOCITY:                              |". },
		{ return  "| ALTITUDE:                              |". },
		{ return  "+----------------------------------------+". },
		{ return  "| APOAPSIS :                             |". },
		{ return  "| PERIAPSIS:                             |". },
		{ return  "+----------------------------------------+". }
	).
	__printLines(lines).
}

function updateDisplay {
	local lines to list(
		{ return  "+----------------------------------------+". },
		{ return  "|                LAUNCHER                |". },
		{ return  "+----------------------------------------+". },
		{ return  "| SHIP: " + ship:name. },
		{ return  "| PHASE: " + state. },
		{ return  "| PIITCH: " + targetPitch + " degrees". },
		{ return  "| VELOCITY: " + round(ship:velocity:surface:mag) + " m/s". },
		{ return  "| ALTITUDE: " + round(ship:altitude) + "m". },
		{ return  "+----------------------------------------+". },
		{ return  "| APOAPSIS : " + round(ship:apoapsis) + "m". },
		{ return  "| PERIAPSIS: " + round(ship:periapsis) + "m". },
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
