//set displaySeparator to "+----------------------------------------+".
set infoOffset to 10.  // Increased for more display lines

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
        { return  "|               PROP LANDER              |". },
        { return  "+----------------------------------------+". },
        { return  "| SHIP:                                  |". },
        { return  "| PHASE:                                 |". },
        { return  "| ALTITUDE:                              |". },
        { return  "| VERTICAL SPEED:                        |". },
        { return  "| BURN ALTITUDE:                         |". },
        { return  "| TIME TO BURN:                          |". },
        { return  "+----------------------------------------+". }
    ).
    __printLines(lines).
}

function updateDisplay {
    local parameter info is "".
    local lines to list(
        { return  "+----------------------------------------+". },
        { return  "|               PROP LANDER              |". },
        { return  "+----------------------------------------+". },
        { return  "| SHIP: " + ship:name. },
        { return  "| PHASE: " + state. },
        { return  "| ALTITUDE: " + round(shipAlt, 1) + "m". },
        { return  "| VERTICAL SPEED: " + round(descentV, 1) + "m/s". },
        { return  "| BURN ALTITUDE: " + round(burnAlt, 1) + "m". },
        { return  "| TIME TO BURN: " + round(timeToBurn, 1) + "s". },
        { return  "+----------------------------------------+". }
    ).
    __clearDisplay(). __printLines(lines).
    if info:length > 0 {
        updateInfo(info).
    }
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