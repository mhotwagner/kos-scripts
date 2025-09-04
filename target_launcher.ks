clearscreen.

run utils.

// Flight configuration parameters
declare parameter targetDistance to 500.     // Target closest approach distance in meters
declare parameter manageMaxQ to true.        // Throttle back during max Q
declare parameter secondarySafetyAlt to 2000. // Initial climb altitude
declare parameter inFlight to false.         // Whether we're starting mid-flight

// Target validation and setup
if not hastarget {
    print "ERROR: No target selected!".
    print "Please select a target vessel before running this script.".
    wait 5.
}

print "Target: " + target:name.
print "Target distance: " + targetDistance + "m".
wait 2.

run target_launcher_display.

// Calculate optimal launch timing for rendezvous
local function calculateLaunchWindow {
    local targetOrbit to target:obt.
    local targetPeriod to targetOrbit:period.
    local targetAltitude to targetOrbit:apoapsis - body:radius.
    
    // Calculate our desired orbital period to match target
    local ourPeriod to targetPeriod.
    local ourAltitude to targetAltitude.
    
    // Calculate phase angle for rendezvous
    // We want to launch when the target is ahead of us by the right amount
    // so we catch up to it at the rendezvous point
    local phaseAngle to 180. // Start with 180 degrees (opposite side)
    
    // Calculate time to reach orbit
    local timeToOrbit to 300. // Rough estimate, will be refined
    
    // Calculate where target will be when we reach orbit
    local targetAngleInTime to (timeToOrbit / targetPeriod) * 360.
    local desiredPhaseAngle to targetAngleInTime.
    
    // Calculate current phase angle
    local targetAngle to target:obt:trueanomaly.
    local ourAngle to 0. // We're on the ground
    
    // Calculate when to launch
    local currentPhaseAngle to (targetAngle - ourAngle + 360) mod 360.
    local launchDelay to ((desiredPhaseAngle - currentPhaseAngle) / 360) * targetPeriod.
    
    // Ensure positive delay
    if launchDelay < 0 {
        set launchDelay to launchDelay + targetPeriod.
    }
    
    return lexicon(
        "launchDelay", launchDelay,
        "targetPeriod", targetPeriod,
        "targetAltitude", targetAltitude,
        "phaseAngle", currentPhaseAngle
    ).
}

// Calculate optimal launch azimuth for target intercept
local function calculateLaunchAzimuth {
    local targetOrbit to target:obt.
    local targetInclination to targetOrbit:inclination.
    
    // For equatorial targets, launch east (90 degrees)
    // For inclined targets, launch at the inclination angle
    local launchAzimuth to targetInclination.
    
    // Ensure we're launching in the right direction (eastward)
    if launchAzimuth < 0 {
        set launchAzimuth to launchAzimuth + 360.
    }
    
    return launchAzimuth.
}

// Calculate intercept trajectory
local function calculateIntercept {
    local targetOrbit to target:obt.
    local targetAltitude to targetOrbit:apoapsis - body:radius.
    
    // We want to intercept at the target's altitude
    // Calculate the velocity needed for intercept
    local interceptAltitude to targetAltitude.
    local interceptVelocity to getCOV(interceptAltitude).
    
    // Calculate the delta-V needed for the intercept burn
    local currentVelocity to ship:velocity:orbit:mag.
    local deltaV to abs(interceptVelocity - currentVelocity).
    
    return lexicon(
        "interceptAltitude", interceptAltitude,
        "interceptVelocity", interceptVelocity,
        "deltaV", deltaV
    ).
}

// Initialize launch parameters
set launchWindow to calculateLaunchWindow().
set launchAzimuth to calculateLaunchAzimuth().
set interceptData to calculateIntercept().

// Convert units and calculate orbital parameters
set orbitAlt to interceptData["interceptAltitude"].
set orbitV to interceptData["interceptVelocity"].
set safetyAlt to 300.                      // Initial pad clearance altitude

// Initialize flight controls
sas off.                                   // Disable SAS for script control
set targetThrottle to 0.
lock throttle to targetThrottle.
set targetSteering to heading(launchAzimuth, 90). // Point straight up initially
lock steering to targetSteering.

// State machine configuration
local function initializeStates {
    return lexicon(
        // Pre-launch and timing
        "ABORT", "ABORT",
        "WAIT_LAUNCH", "WAITING FOR LAUNCH WINDOW",
        "PRE-LAUNCH", "PRE-LAUNCH",
        "LAUNCH", "LAUNCH",
        "PAD_ROLL", "PAD ROLL",
        "CLIMB_2", "CLIMB TO 2 KM",
        
        // Gravity turn and atmospheric ascent
        "TURN_10", "TURN TO 10 KM",
        "CLIMB_18", "CLIMB TO 18 KM",
        "TURN_45", "TURN TO 45 KM",
        
        // Coast and orbital insertion
        "PREPARE_COAST", "PREPARE TO COAST",
        "ADJUST_APO", "ADJUST APOAPSIS",
        "COAST_SPACE", "COAST TO SPACE",
        "COAST_APO", "COAST TO APO",
        "PREPARE_CIRC", "PREPARE TO CIRCULARIIZE",
        "CIRC", "CIRCULARIIZE",
        "INTERCEPT", "INTERCEPT TARGET",
        "RENDEZVOUS", "RENDEZVOUS",
        "MATCH_VELOCITY", "MATCH VELOCITY",
        "ORBIT", "ORBIT"
    ).
}

// Initialize state machine
set stateNames to initializeStates().
set state to choose stateNames["WAIT_LAUNCH"] if not inFlight else stateNames["CLIMB_2"].
set orbiting to false.
set tickDelay to 0.01.                     // Main loop delay
set once to false.                         // State entry flag

// Initialize display
updateDisplay().

set states to lexicon().

// Wait for optimal launch window
states:add(stateNames["WAIT_LAUNCH"], {
    if not once {
        set once to true.
        updateInfo("Calculating launch window...").
        wait 1.
    }
    
    local timeToLaunch to launchWindow["launchDelay"].
    local targetPeriod to launchWindow["targetPeriod"].
    
    if timeToLaunch > 60 {
        updateInfo("Launch in " + round(timeToLaunch/60, 1) + " minutes").
        wait 10.
    } else if timeToLaunch > 10 {
        updateInfo("Launch in " + round(timeToLaunch) + " seconds").
        wait 1.
    } else if timeToLaunch > 0 {
        updateInfo("Launch in " + round(timeToLaunch) + " seconds").
        wait 0.1.
    } else {
        updateInfo("Launch window reached!").
        wait 1.
        set state to stateNames["PRE-LAUNCH"].
        set once to false.
    }
}).

states:add(stateNames["PRE-LAUNCH"], {
    from { local countdown is 5. } until countdown = 0 step { set countdown to countdown - 1. } do {
        updateInfo("Launching to " + target:name + " in " + countdown).
        wait 1.
    }
    set targetThrottle to 1.
    set targetSteering to heading(launchAzimuth, 90).
    set state to stateNames["LAUNCH"].
}).

states:add(stateNames["LAUNCH"], { 
    updateInfo("Launching to target"). 
    stage. 
    set state to stateNames["PAD_ROLL"]. 
}).

states:add(stateNames["PAD_ROLL"], { // 2: pad roll
    if ship:altitude > safetyAlt {
        updateInfo("Beginning gravity turn").
        if gear { gear off. }
        set targetSteering to heading(launchAzimuth, 85).
        set state to stateNames["CLIMB_2"].
    }
}).

states:add(stateNames["CLIMB_2"], { // 3: climb to 2km
    autostage().
    if not once and ship:altitude > 200 { set once to true. updateInfo("Climbing to " + secondarySafetyAlt + "m"). }
    if ship:altitude > secondarySafetyAlt { set state to stateNames["TURN_10"]. set once to false. }
}).

states:add(stateNames["TURN_10"], {
    autostage().
    if not once { set once to true. updateInfo("Turning to 45 degrees at 10km"). }
    
    set targetPitch to max(5, 90 - (alt:radar/10000 * 45)).
    set targetSteering to heading(launchAzimuth, targetPitch).
    
    if ship:altitude > 5000 and manageMaxQ { updateInfo("Throttling back through max q"). lock throttle to .7. }
    
    if ship:altitude > 10000 {
        if manageMaxQ { updateInfo("Throttling up"). }
        lock throttle to 1.
        set state to stateNames["CLIMB_18"].
        set once to false.
    }
}).

states:add(stateNames["CLIMB_18"], { // 5: climb to 18km
    autostage().
    if not once and ship:altitude > 11000 { set once to true. updateInfo("Climbing to 18km"). }
    
    set targetSteering to heading(launchAzimuth, 45).
    
    if ship:altitude > 18000 { set state to stateNames["TURN_45"]. set once to false. }
}).

states:add(stateNames["TURN_45"], { // 6: turn to 45km
    autostage().
    if not once { set once to true. updateInfo("Turning to 5 degrees at 45km"). }
    
    set targetPitch to max(5, 45 - ((alt:radar-18000)/(45000-18000) * 45)).
    set targetSteering to heading(launchAzimuth, targetPitch).
    
    if ship:apoapsis > orbitAlt {
        set state to stateNames["PREPARE_COAST"].
        set once to false.
    }
    else if ship:apoapsis > orbitAlt * .995 { lock throttle to .05. }
    else if ship:apoapsis > orbitAlt * .95 { lock throttle to .25. }
}).

states:add(stateNames["PREPARE_COAST"], { // 7: Prepare to coast
    updateInfo("Preparing to coast").
    lock throttle to 0. wait 1.
    set targetSteering to heading(launchAzimuth, 3). // Almost horizontal
    wait 3.
    set state to stateNames["COAST_SPACE"].
}).

states:add(stateNames["ADJUST_APO"], { // 8: Adjust apoapsis
    if not once {
        set once to true.
        updateInfo("Adjusting apoapsis").
        lock throttle to .1.
    }
    if ship:apoapsis > orbitAlt * 1.002 { 
        lock throttle to 0. 
        set state to stateNames["COAST_SPACE"].
        set once to false.
    }
}).

states:add(stateNames["COAST_SPACE"], {
    if not once { set once to true. updateInfo("Coasting to space"). }
    set targetSteering to heading(launchAzimuth, 3).
    if ship:apoapsis < orbitAlt * .999 { set state to stateNames["ADJUST_APO"]. set once to false. }
    if ship:altitude > 70000 { set state to stateNames["COAST_APO"]. set once to false. }
}).

states:add(stateNames["COAST_APO"], {
    if not once {
        set tickDelay to 1. set once to true.
        updateInfo("Coasting to apoapsis").
        panels on.
        lights on.
        run ant.
        set deltaV to abs((getCOV(ship:apoapsis) - getApoV())).
        set burnTime to deltaV / getA().
    }
    // Point prograde for circularization
    lock targetSteering to prograde.
    if (eta:apoapsis - (burnTime / 2)) < 60 {
        set state to stateNames["PREPARE_CIRC"]. set once to false.
    }
}).

states:add(stateNames["PREPARE_CIRC"], {
    if not once {
        set tickDelay to .1.
        updateInfo("Preparing to circularize").
        set once to true.
    }
    updateinfo(round(burnTime) + " s + " + round(deltaV) + "m/s burn in " + round(eta:apoapsis - ((2 * burnTime) / 3)) + " seconds").
    // Point prograde for circularization
    lock targetSteering to prograde.
    if eta:apoapsis < ((2 * burnTime) / 3) {
        set state to stateNames["CIRC"]. set once to false.
    }
}).

states:add(stateNames["CIRC"], { // 11: Circularize
    if not once {
        set once to true.
        set tickDelay to .01.
        updateInfo("Circularizing").
        lock throttle to 1.
        // Store initial apoapsis for adaptive steering
        set initialApoapsis to ship:apoapsis.
        set burnStartTime to missionTime.
    }
    // Adaptive steering for finite burns
    autostage().
    
    // Calculate how much of the burn has completed
    set elapsedBurnTime to missionTime - burnStartTime.
    set burnProgress to elapsedBurnTime / burnTime.
    
    // For long burns, gradually adjust steering to compensate for apoapsis movement
    if burnTime > 30 { // Only use adaptive steering for burns longer than 30 seconds
        // Calculate how much the apoapsis has moved
        set apoapsisShift to ship:apoapsis - initialApoapsis.
        
        // If apoapsis has moved significantly, adjust steering
        if abs(apoapsisShift) > 1000 { // More than 1km shift
            // Calculate compensation angle (simplified)
            set compensationAngle to (apoapsisShift / 10000) * 5. // 5 degrees per 10km shift
            set compensationAngle to max(-10, min(10, compensationAngle)). // Limit to ±10 degrees
            
            // Apply compensation by adjusting pitch slightly above prograde
            set targetPitch to 90 + compensationAngle.
            set targetSteering to heading(launchAzimuth, targetPitch).
        } else {
            // Use standard prograde steering
            lock targetSteering to prograde.
        }
    } else if burnTime > 60 { // Alternative: For very long burns (>60s), burn horizontal
        // Burn towards 0° (horizontal) to minimize apoapsis movement
        // This can be more effective for very low TWR stages
        set targetSteering to heading(launchAzimuth, 0).
    } else {
        // Use standard prograde steering
        lock targetSteering to prograde.
    }
    
    if ship:periapsis > ship:apoapsis * .75 { lock throttle to .1. }
    if ship:periapsis > ship:apoapsis * .95 { lock throttle to .05. }
    if ship:periapsis > orbitAlt * .95 and ship:apoapsis > orbitAlt * 1.05 {
        set state to stateNames["INTERCEPT"]. set once to false.
    }
}).

states:add(stateNames["INTERCEPT"], {
    if not once {
        set once to true.
        updateInfo("Calculating intercept...").
        set tickDelay to 0.1.
    }
    
    // Calculate distance to target
    local distance to target:distance.
    local relativeVelocity to (target:velocity:orbit - ship:velocity:orbit):mag.
    
    // If we're close enough, start rendezvous
    if distance < 10000 { // Within 10km
        set state to stateNames["RENDEZVOUS"].
        set once to false.
    } else {
        // Calculate intercept burn
        local interceptVector to target:position - ship:position.
        local interceptDirection to interceptVector:normalized.
        
        // Point towards target
        set targetSteering to lookdirup(interceptDirection, ship:facing:topvector).
        
        // Small burn to adjust intercept
        if distance > 50000 { // More than 50km away
            lock throttle to 0.1.
        } else {
            lock throttle to 0.05.
        }
        
        updateInfo("Intercepting: " + round(distance/1000, 1) + "km away").
    }
}).

states:add(stateNames["RENDEZVOUS"], {
    if not once {
        set once to true.
        updateInfo("Rendezvous phase").
        lock throttle to 0.
    }
    
    // Calculate distance to target
    local distance to target:distance.
    local relativeVelocity to (target:velocity:orbit - ship:velocity:orbit):mag.
    
    // If we're at the target distance, match velocities
    if distance <= targetDistance {
        set state to stateNames["MATCH_VELOCITY"].
        set once to false.
    } else {
        // Approach the target slowly
        local approachVector to target:position - ship:position.
        local approachDirection to approachVector:normalized.
        
        // Point towards target
        set targetSteering to lookdirup(approachDirection, ship:facing:topvector).
        
        // Very small burns for approach
        if distance > targetDistance * 2 {
            lock throttle to 0.02.
        } else {
            lock throttle to 0.01.
        }
        
        updateInfo("Approaching: " + round(distance) + "m away").
    }
}).

states:add(stateNames["MATCH_VELOCITY"], {
    if not once {
        set once to true.
        updateInfo("Matching velocities").
        lock throttle to 0.
    }
    
    // Calculate relative velocity
    local relativeVelocity to target:velocity:orbit - ship:velocity:orbit.
    local relativeSpeed to relativeVelocity:mag.
    
    // If velocities are matched, we're done
    if relativeSpeed < 1 { // Less than 1 m/s relative velocity
        set state to stateNames["ORBIT"].
        set once to false.
    } else {
        // Point opposite to relative velocity for braking
        local brakeDirection to -relativeVelocity:normalized.
        set targetSteering to lookdirup(brakeDirection, ship:facing:topvector).
        
        // Burn to match velocities
        if relativeSpeed > 10 {
            lock throttle to 0.1.
        } else if relativeSpeed > 5 {
            lock throttle to 0.05.
        } else {
            lock throttle to 0.02.
        }
        
        updateInfo("Matching velocities: " + round(relativeSpeed, 1) + "m/s").
    }
}).

states:add(stateNames["ORBIT"], { // 12: Orbit!
    set tickDelay to .1.
    lock throttle to 0.
    updateInfo("Rendezvous complete!").
    set orbiting to true.
}).

until orbiting {
    states[state]().
    updateDisplay().
    wait tickDelay.
}

// shutdown systems
unlock steering.
unlock throttle.
sas on.

print "Target launcher complete!".
print "Distance to target: " + round(target:distance) + "m".
print "Relative velocity: " + round((target:velocity:orbit - ship:velocity:orbit):mag, 1) + "m/s".

