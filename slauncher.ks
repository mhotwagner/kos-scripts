clearscreen.

// Import required utilities
// Configuration parameters with default values
run utils.

declare parameter orbitAltKm to 100.
declare parameter rollAngle to 90.
declare parameter manageMaxQ to true.
declare parameter secondarySafetyAlt to 2000.
declare parameter inFlight to false.
declare parameter initialState to "PRE-LAUNCH".

// Convert parameters to required units and calculate orbital parameters
SET orbitAlt TO orbitAltKm * 1000.
set orbitV to getCOV(orbitAlt).
set safetyAlt to 300.

// Initialize flight controls
sas off.
set targetThrottle to 0.
lock throttle to targetThrottle.
set targetSteering to up + r(0, 0, rollAngle).
lock steering to targetSteering.

// State management
set targetPitch to "x".
set orbiting to false.
set tickDelay to .01.
set once to false.

run launcher_display.


// Define state names
local function initStates {
    return lexicon(
        "PRE-LAUNCH", "PRE-LAUNCH",
        "LAUNCH", "LAUNCH",
        "PAD_ROLL", "PAD ROLL",
        "CLIMB_2", "CLIMB TO 2 KM",
        "TURN_10", "TURN TO 10 KM",
        "CLIMB_18", "CLIMB TO 18 KM",
        "TURN_45", "TURN TO 45 KM",
        "PREPARE_COAST", "PREPARE TO COAST",
        "ADJUST_APO", "ADJUST APOAPSIS",
        "COAST_SPACE", "COAST TO SPACE",
        "COAST_APO", "COAST TO APO",
        "PREPARE_CIRC", "PREPARE TO CIRCULARIIZE",
        "CIRC", "CIRCULARIIZE",
        "ORBIT", "ORBIT"
    ).
}
set stateNames to initStates().

// Initialize state
set state to choose stateNames["CLIMB_2"] if inFlight else stateNames["PRE-LAUNCH"].

// Initialize display
updateDisplay().

// State handlers
set states to lexicon().

// Pre-launch state
states:add(stateNames["PRE-LAUNCH"], {
    from { local countdown is 5. }
    until countdown = 0
    step { set countdown to countdown - 1. }
    do {
        updateInfo("Launching to " + orbitAltKm + "km orbit in " + countdown).
        wait 1.
    }
    set targetThrottle to 1.
    set targetSteering to up + r(0, 0, rollAngle).
    set state to stateNames["LAUNCH"].
}).

// Launch state
states:add(stateNames["LAUNCH"], {
    updateInfo("Launching").
    stage.
    set state to stateNames["PAD_ROLL"].
}).

// Pad roll state
states:add(stateNames["PAD_ROLL"], {
    if ship:altitude > safetyAlt {
        updateInfo("Rolling away from pad").
        if gear { gear off. }
        set targetSteering to up + r(0, -5, rollAngle).
        set state to stateNames["CLIMB_2"].
    }
}).

// ... existing code for other states ...

// Main flight loop
until orbiting {
    if states:haskey(state) {
        states[state]().
        updateDisplay().
        wait tickDelay.
    } else {
        updateInfo("ERROR: Invalid state " + state).
        break.
    }
}

// Shutdown systems
unlock steering.
unlock throttle.
sas on.