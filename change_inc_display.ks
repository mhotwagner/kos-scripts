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
        { return  "|          INCLINATION CHANGE            |". },
        { return  "+----------------------------------------+". },
        { return  "| SHIP:                                  |". },
        { return  "| PHASE:                                 |". },
        { return  "| CURRENT INC:                           |". },
        { return  "| TARGET INC:                            |". },
        { return  "| NEXT NODE:                             |". },
        { return  "| DELTA-V:                               |". },
        { return  "+----------------------------------------+". }
    ).
    __printLines(lines).
}

function updateDisplay {
    parameter state_name.
    parameter target_inc.
    parameter delta_v.

    local nodeText to "NO NODE".
    // Check if either ascending or descending node exists
    if (defined ship:orbit:ascendingnode and defined ship:orbit:descendingnode) {
        set nodeText to choose "AN: " + round(ship:orbit:ascendingnode) + "s" 
                        if (ship:orbit:ascendingnode < ship:orbit:descendingnode)
                        else "DN: " + round(ship:orbit:descendingnode) + "s".
    }
    
    local lines to list(
        { return  "+----------------------------------------+". },
        { return  "|          INCLINATION CHANGE            |". },
        { return  "+----------------------------------------+". },
        { return  "| SHIP: " + ship:name. },
        { return  "| PHASE: " + state_name. },
        { return  "| CURRENT INC: " + round(ship:orbit:inclination, 2) + "°". },
        { return  "| TARGET INC: " + round(target_inc, 2) + "°". },
        { return  "| NEXT NODE: " + nodeText. },
        { return  "| DELTA-V: " + round(delta_v, 1) + " m/s". },
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