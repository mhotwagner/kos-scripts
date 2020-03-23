clearscreen.

run utils.

declare parameter orbitAltKm to 100.
declare parameter inclination to 90.
declare parameter stageFirst to false.

SET orbitAlt TO orbitAltKm * 1000.
set orbitV to getOrbitV(orbitAlt).
set safetyAlt to 100.

sas off.

set targetSteering to up.
set targetThrottle to 0.

lock steering to targetSteering.
lock throttle to targetThrottle.

set orbiting to false.
set stateNames to lexicon().
set state_initial to "INITIAL".
set state_launch to "LAUNCH".

set state_safety to "SAFETY CLIMB".
set state_climb to "CLIMB".
set state_coast to "COAST".
set state_prepareCirc to "PREPARE TO CIRCULARIIZE".
set state_circ to "CIRCULARIIZE".
set state_orbit to "ORBIT".

set state to state_initial.
set targetPitch to "x".
set tickDelay to .01.
set once to false.

run launcher_utils.
run launcher_display.
updateDisplay().

set states to lexicon().
states:add(state_initial, {
		from { local countdown is 5. } until countdown = 0 step { set countdown to countdown - 1. } do {
			updateInfo("Launching to " + orbitAlt + "m orbit in " + countdown).
			wait 1.
		}
		set targetPitch to 90.
		set state to state_launch.
}).
states:add(state_launch, {
	set targetSteering to up.
	if stageFirst { stage. }
	set targetThrottle to 0.1.
	set state to state_safety.
	
}).
states:add(state_safety, {
	if not once { set once to true. updateInfo("Climbing to safe height"). }
	if alt:radar > safetyAlt {
		set state to state_climb.
		set once to false.
	}
}).
states:add(state_climb, {
	if not once	{
		set once to true.
		set targetThrottle to 1.
		updateInfo("Climbing to " + orbitAltKm + "km").
	}
	set targetSteering to heading(inclination, 45).
	
	
	if ship:apoapsis > orbitAlt {
		set state to state_coast.
		set once to false.
	}
	else if ship:apoapsis > orbitAlt * .995 { lock throttle to .05. }
	else if ship:apoapsis > orbitAlt * .95 { lock throttle to .25. }

}).
states:add(state_coast, {
	if not once {
		updateInfo("Coasting to apoapsis...").
		lock throttle to 0. wait 1.
		set tickDelay to 1. set once to true.
		set deltaV to (getOrbitV(ship:apoapsis) - getApoV()).
		set burnTime to deltaV / getA().
	}
	set targetSteering to heading(inclination, 0).
	if (eta:apoapsis - (burnTime / 2)) <  10 {
		set state to state_prepareCirc. set once to false.
	}	
}).
states:add(state_prepareCirc, {
	if not once {
		set tickDelay to .1.
		updateInfo("Preparing to circularize").
		set once to true.
	}
	updateinfo( round(burnTime) + " s + " + round(deltaV) + "m/s burn in  " + round(eta:apoapsis - (burnTime/2)) + " seconds").
	set targetSteering to heading(inclination, 0).
	if eta:apoapsis < (burnTime / 2) {
		set tickDelay to .01. set state to state_circ. set once to false.
	}
}).
states:add(state_circ, {
	if not once {
		set once to true.
		updateInfo("Circularizing").
		set targetThrottle to 1.
	}
	set targetSteering to heading(inclination, 0).
	if ship:velocity > orbitV * .75 { set targetThrottle to .1. }
	if ship:velocity > orbitV * .95 { set targetThrottle to .05. }
	if ship:velocity > orbit {
	  	set state to state_orbit. set once to false.
	}
}).
states:add(state_orbit, {
		set tickDelay to .1.
		set targetThrottle to 0.
		updateInfo("Orbiting!").
		set orbiting to true.
}).

until orbiting {
	states[state]().
	updateDisplay().
	wait tickDelay.
}

// shutdown systems
panels on.
lights on.
unlock steering.
unlock throttle.
sas on.