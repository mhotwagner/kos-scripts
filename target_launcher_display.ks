//set displaySeparator to "+----------------------------------------+".
set infoOffset to 15.  // Increased due to more display lines

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
        { return  "|            TARGET LAUNCHER             |". },
        { return  "+----------------------------------------+". },
        { return  "| SHIP:                                  |". },
        { return  "| TARGET:                                |". },
        { return  "| PHASE:                                 |". },
        { return  "| ALTITUDE:                              |". },
        { return  "| APOAPSIS:                              |". },
        { return  "| PERIAPSIS:                             |". },
        { return  "| TIME TO APO:                           |". },
        { return  "| VELOCITY:                              |". },
        { return  "| TARGET DISTANCE:                       |". },
        { return  "| RELATIVE VELOCITY:                     |". },
        { return  "| TARGET ALTITUDE:                       |". },
        { return  "+----------------------------------------+". }
    ).
    __printLines(lines).
}

function updateDisplay {
    local targetName to "NONE".
    local targetDistance to "N/A".
    local relativeVelocity to "N/A".
    local targetAltitude to "N/A".
    
    if hastarget {
        set targetName to target:name.
        set targetDistance to round(target:distance/1000, 1) + "km".
        set relativeVelocity to round((target:velocity:orbit - ship:velocity:orbit):mag, 1) + "m/s".
        set targetAltitude to round((target:obt:apoapsis - body:radius)/1000, 1) + "km".
    }
    
    local lines to list(
        { return  "+----------------------------------------+". },
        { return  "|            TARGET LAUNCHER             |". },
        { return  "+----------------------------------------+". },
        { return  "| SHIP: " + ship:name. },
        { return  "| TARGET: " + targetName. },
        { return  "| PHASE: " + state. },
        { return  "| ALTITUDE: " + round(altitude/1000, 1) + "km (" + round(alt:radar/1000, 1) + "km AGL)". },
        { return  "| APOAPSIS: " + round(ship:apoapsis/1000, 1) + "km". },
        { return  "| PERIAPSIS: " + round(ship:periapsis/1000, 1) + "km". },
        { return  "| TIME TO APO: " + round(eta:apoapsis) + "s". },
        { return  "| VELOCITY: " + round(ship:velocity:orbit:mag) + "m/s". },
        { return  "| TARGET DISTANCE: " + targetDistance. },
        { return  "| RELATIVE VELOCITY: " + relativeVelocity. },
        { return  "| TARGET ALTITUDE: " + targetAltitude. },
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
