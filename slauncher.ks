clearscreen.

run utils.


// Flight configuration parameters
declare parameter orbitAltKm to 100.     
declare parameter inclination to 0.
declare parameter manageMaxQ to true.       // Throttle back during max Q
declare parameter boostbackStage to 0.
declare parameter boostbackDeltaV to 500.
declare parameter boostbackStage2 to 0.
declare parameter boostbackDeltaV2 to 500.
// declare parameter inFlight to false.        // Whether we're starting mid-flight

set inFlight to ship:altitude > 500.
set secondarySafetyAlt to 2000.

run launcher_display.
// Convert units and calculate orbital parameters
set orbitAlt to orbitAltKm * 1000.         // Convert km to meters
set orbitV to getCOV(orbitAlt).            // Calculate target orbital velocity
set safetyAlt to 300.                      // Initial pad clearance altitude

// Calculate launch azimuth

set launchAzimuth to inclination.

// Initialize flight controls
sas off.                                   // Disable SAS for script control
set targetThrottle to 0.
lock throttle to targetThrottle.
set targetSteering to heading(launchAzimuth, 90). // Point straight up initially
lock steering to targetSteering.

function checkBoostback {

	if boostbackStage > 0 {
		if stage:number = boostbackStage {
			if SHIP:STAGEDELTAV(SHIP:STAGENUM):CURRENT <= boostbackDeltaV {
				lock throttle to 0.
				stage.
				wait 2.
				lock throttle to 1.
				return true.
			}
		}
	} else if boostbackStage2 > 0 {
		if stage:number = boostbackStage2 {
			if SHIP:STAGEDELTAV(SHIP:STAGENUM):CURRENT <= boostbackDeltaV2 {
				stage.
				wait 2.
				return true.
			}
		}
	}

	return false.
}

function hasMainFairing {
	set fl to ship:partsdubbed("mainFairing").
	if fl:length > 0 {
		return true.
	}
	return false.
}

function blowFairing {
	set fairingList to ship:partsdubbed("mainFairing").
	for fairing in fairingList {
		set m to fairing:getmodule("ModuleProceduralFairing").
		m:doevent("deploy").
	}
}

// State machine configuration
local function initializeStates {
    return lexicon(
        // Pre-launch and initial ascent
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
        "ORBIT", "ORBIT"
    ).
}

// Initialize state machine
set stateNames to initializeStates().
set state to choose stateNames["CLIMB_2"] if inFlight else stateNames["PRE-LAUNCH"].
set orbiting to false.
set tickDelay to 0.01.                     // Main loop delay
set once to false.                         // State entry flag

// Initialize display
updateDisplay().

set states to lexicon().
states:add(stateNames["PRE-LAUNCH"], {
		from { local countdown is 5. } until countdown = 0 step { set countdown to countdown - 1. } do {
			updateInfo("Launching to " + orbitAltKm + "km orbit at " + "in "+ countdown).
			wait 1.
		}
		set targetThrottle to 1.
		set targetSteering to heading(launchAzimuth, 90).
		set state to stateNames["LAUNCH"].
}).
states:add(stateNames["LAUNCH"], { updateInfo("Launching"). stage. set state to stateNames["PAD_ROLL"]. }).
states:add(stateNames["PAD_ROLL"], { // 2: pad roll
		if ship:altitude > safetyAlt {
			updateInfo("Beginning gravity turn").
			if gear { gear off. }
			set targetSteering to heading(launchAzimuth, 85).
			set state to stateNames["CLIMB_2"].
		}
}).
states:add(stateNames["CLIMB_2"], { // 3: climb to 2km
		if not checkBoostback() { autostage(). }
		if not once and ship:altitude > 200 { set once to true. updateInfo("Climbing to " + secondarySafetyAlt + "m"). }
		if ship:altitude > secondarySafetyAlt { set state to stateNames["TURN_10"]. set once to false. }
}).
states:add(stateNames["TURN_10"], {
		if not checkBoostback() { autostage(). }
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
		if not checkBoostback() { autostage(). }
		if not once and ship:altitude > 11000 { set once to true. updateInfo("Climbing to 18km"). }
		
		set targetSteering to heading(launchAzimuth, 45).
		
		if ship:altitude > 18000 { set state to stateNames["TURN_45"]. set once to false. }
}).
states:add(stateNames["TURN_45"], { // 6: turn to 45km
		if not checkBoostback() { autostage(). }
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
		if hasMainFairing() { blowFairing(). wait 5. }
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
		if not checkBoostback() { autostage(). }
		
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
			set state to stateNames["ORBIT"]. set once to false.
		}
}).
states:add(stateNames["ORBIT"], { // 12: Orbit!
		set tickDelay to .1.
		lock throttle to 0.
		updateInfo("Orbiting!").
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