clearscreen.

run utils.

sas off.

set targetHeading to ship:prograde.
set targetThrottle to 0.
lock steering to targetHeading.
lock throttle to targetThrottle.
set circularized to false.

set state_init to "INITIALIZING".
set state_tracking to "TRACKING".
set state_preBurn to "PRE BURN".
set state_circ to "CIRCULARIZE".

set state to state_init.
set tickDelay to .1.
set once to false.

run circularize_display.

set states to lexicon().
states:add(state_init, {
	set deltaV to (getOrbitV(ship:apoapsis) - getApoV()).
	set burnTime to deltaV / getA().
	updateDisplay().
	wait 5.

}).
states:add(state_coastToApo, {
	if not once {
		set tickDelay to 1. set once to true.
		updateInfo("Coasting to apoapsis").
	}
	set targetPitch to 0. updateHeading().
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
		updateinfo(round(deltaV) + " | " + round(burnTime) + " | " + round(eta:apoapsis - (burnTime/2))).
		set targetPitch to 0. updateHeading().
		if eta:apoapsis < (burnTime / 2) {
			set tickDelay to .01. set state to state_circ. set once to false.
		}
}).
states:add(state_circ, { // 11: Circularize
		if not once {
			set once to true.
			updateInfo("Circularizing").
			lock throttle to 1.
		}
		updateHeading().
		if ship:periapsis > orbitAlt * .75 { lock throttle to .1. }
		if ship:periapsis > orbitAlt * .95 { lock throttle to .05. }
		if ship:periapsis > orbitAlt * .999 or ship:apoapsis > orbitAlt * 1.01 {
		  	set state to state_orbit. set once to false.
	  }
}).
states:add(state_orbit, { // 12: Orbit!
		set tickDelay to .1.
		lock throttle to 0.
		updateInfo("Orbiting!").
		set orbiting to true.
}).

until circularized {
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