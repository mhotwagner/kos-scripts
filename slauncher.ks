clearscreen.

run utils.

declare parameter orbitAltKm to 100.
declare parameter rollAngle to 90.
declare parameter manageMaxQ to true.
declare parameter secondarySafetyAlt to 2000.
declare parameter inFlight to false.

declare parameter initialState to "PRE-LAUNCH".

SET orbitAlt TO orbitAltKm * 1000.
set orbitV to getCOV(orbitAlt).
set safetyAlt to 300.

sas off.
set targetThrottle to 0.
lock throttle to targetThrottle.
set targetSteering to up + r(0, 0, rollAngle).
lock steering to targetSteering.

set targetPitch to "x".


set orbiting to false.
set stateNames to lexicon().
set state_preLaunch to "PRE-LAUNCH".
set state_launch to "LAUNCH".
set state_padRoll to "PAD ROLL".
set state_climb2 to "CLIMB TO 2 KM".
set state_turn10 to "TURN TO 10 KM".
set state_climb18 to "CLIMB TO 18 KM".
set state_turn_45 to "TURN TO 45 KM".
set state_prepareCoast to "PREPARE TO COAST".
set state_adjustApo to "ADJUST APOAPSIS".
set state_coastToSpace to "COAST TO SPACE".
set state_coastToApo to "C".
set state_prepareCirc to "PREPARE TO CIRCULARIIZE".
set state_circ to "CIRCULARIIZE".
set state_orbit to "ORBIT".

set state to choose state_climb2 if inFlight else state_preLaunch.
set tickDelay to .01.
set once to false.

run launcher_utils.
run launcher_display.
updateDisplay().

set states to lexicon().
states:add(state_preLaunch, {
		from { local countdown is 5. } until countdown = 0 step { set countdown to countdown - 1. } do {
			updateInfo("Launching to " + orbitAltKm + "km orbit in " + countdown).
			wait 1.
		}
		set targetThrottle to 1.
		set targetSteering to up + r(0, 0, rollAngle).
		set state to state_launch.
}).
states:add(state_launch, { updateInfo("Launching"). stage. set state to state_padRoll. }).
states:add(state_padRoll, { // 2: pad roll
		if ship:altitude > safetyAlt {
			updateInfo("Rolling away from pad").
			if gear { gear off. }
			set targetSteering to up + r(0, -5, rollAngle).
			set state to state_climb2.
		}
}).
states:add(state_climb2, { // 3: climb to 2km
		autostage().
		if not once and ship:altitude > 200 { set once to true. updateInfo("Climbing to " + secondarySafetyAlt + "m"). }
		if ship:altitude > secondarySafetyAlt { set state to state_turn10. set once to false. }
}).
states:add(state_turn10, {
		autostage().
		if not once { set once to true. updateInfo("Turning to 45 degrees at 10km"). }
		
		set targetPitch to -1 * (90 - min(85, round(90 - (alt:radar/10000 * 45)))).
		set targetSteering to up + r(0, targetPitch, rollAngle).
		
		if ship:altitude > 5000 and manageMaxQ { updateInfo("Throttling back through max q"). lock throttle to .7. }
		
		if ship:altitude > 10000 {
			if manageMaxQ { updateInfo("Throttling up"). }
			lock throttle to 1.
			set state to state_climb18.
			set once to false.
		}
}).
states:add(state_climb18, { // 5: climb to 18km
		autostage().
		if not once and ship:altitude > 11000 { set once to true. updateInfo("Climbing to 18km"). }
		
		set targetSteering to up + r(0, -45, rollAngle).
		
		if ship:altitude > 18000 { set state to state_turn_45. set once to false. }
}).
states:add(state_turn_45, { // 6: turn to 45km
		autostage().
		if not once { set once to true. updateInfo("Turning to 5 degrees at 45km"). }
		
		set targetPitch TO -1 * (90 - max(5, round(45 - ((alt:radar-18000)/(45000-18000) * 45)))).
		set targetSteering to up + r(0, targetPitch, rollAngle).
		
		if ship:apoapsis > orbitAlt {
			set state to state_prepareCoast.
			set once to false.
		}
		else if ship:apoapsis > orbitAlt * .995 { lock throttle to .05. }
		else if ship:apoapsis > orbitAlt * .95 { lock throttle to .25. }
}).
states:add(state_prepareCoast, { // 7: Prepare to coast
		updateInfo("Peparing to coast").
		lock throttle to 0. wait 1.
		set targetSteering to up + r(0, -87, rollAngle).
		wait 3.
		set state to state_coastToSpace.
}).
states:add(state_adjustApo, { // 8: Adjust apoapsis
		if not once {
			set once to true.
			updateInfo("Adjusting apoapsis").
			lock throttle to .1.
		}
		if ship:apoapsis > orbitAlt * 1.002 { 
			lock throttle to 0. 
			set state to state_coastToSpace.
			set once to false.
		}
}).
states:add(state_coastToSpace, {
		if not once { set once to true. updateInfo("Coasting to space"). }
		set targetSteering to up + r(0, -87, rollAngle).
		if ship:apoapsis < orbitAlt * .999 { set state to state_adjustApo. set once to false. }
		if ship:altitude > 70000 { set state to state_coastToApo. set once to false. }
}).
states:add(state_coastToApo, {
	if not once {
		set tickDelay to 1. set once to true.
		updateInfo("Coasting to apoapsis").
		panels on.
		lights on.
		set deltaV to abs((getCOV(ship:apoapsis) - getApoV())).
		set burnTime to deltaV / getA().
	}
	set targetSteering to up + r(0, -90, rollAngle).
	if (eta:apoapsis - (burnTime / 2)) <  60 {
		set state to state_prepareCirc. set once to false.
	}
}).
states:add(state_prepareCirc, {
		if not once {
			set tickDelay to .1.
			updateInfo("Preparing to circularize").
			set once to true.
		}
		updateinfo( round(burnTime) + " s + " + round(deltaV) + "m/s burn in  " + round(eta:apoapsis - ((2 * burnTime) / 3)) + " seconds").
		set targetSteering to up + r(0, -90, rollAngle).
		if eta:apoapsis < ((2 * burnTime) / 3) {
			set state to state_circ. set once to false.
		}
}).
states:add(state_circ, { // 11: Circularize
		if not once {
			set once to true.
			set tickDelay to .01.
			updateInfo("Circularizing").
			lock throttle to 1.
			//set lastE to ship:orbit:eccentricity.
			//set moreCircular to true.
		}
		set targetSteering to up + r(0, -90, rollAngle).
		if ship:periapsis > ship:apoapsis * .75 { lock throttle to .1. }
		if ship:periapsis > ship:apoapsis * .95 { lock throttle to .05. }
		if ship:periapsis > orbitAlt * .95 and ship:apoapsis > orbitAlt * 1.05 {
		  	set state to state_orbit. set once to false.
	    }
	    //set moreCircular to choose true if ship:orbit:eccentricity >  lastE else false.
	    //set lastE to ship:orbit:eccentricity.
}).
states:add(state_orbit, { // 12: Orbit!
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