clearscreen.

run utils.

sas off.

set targetHeading to ship:prograde.
set targetThrottle to 0.
lock steering to targetHeading.
lock throttle to targetThrottle.
set circularized to false.

set state_init to "INITIALIZE".
set state_coast to "COAST".
set state_preBurn to "PRE BURN".
set state_circ to "CIRCULARIZE".
set state_final to "FINALIZE".

set state to state_init.
set tickDelay to .1.
set once to false.


run circularize_display.

set states to lexicon().
states:add(state_init, {
	set deltaV to (getOrbitV(ship:apoapsis) - getApoV()).
	set burnTime to deltaV / getA().
	updateDisplay().
	set state to state_coast.
}).
states:add(state_coast, {
	if not once {
		set tickDelay to 1. set once to true.
		updateInfo("Coasting to burn").
	}
	if (eta:apoapsis - (burnTime / 2)) <  10 {
		set state to state_preBurn. set once to false.
	}
}).
states:add(state_preBurn, {
	if not once {
		set tickDelay to .01.
		updateInfo("Preparing to circularize").
		set once to true.
	}

	if (eta:apoapsis - (burnTime / 2)) <  0 {
		set tickDelay to .01. set state to state_circ. set once to false.
	}
}).
states:add(state_circ, {
		if not once {
			set once to true.
			updateInfo("Circularizing").
			lock throttle to 1.
		}
		if ship:periapsis > orbitAlt * .75 { lock throttle to .1. }
		if ship:periapsis > orbitAlt * .95 { lock throttle to .05. }
		if ship:periapsis > orbitAlt * .999 and ship:apoapsis >= orbitAlt {
		  	set state to state_final. set once to false.
	  }
}).
states:add(state_final, {
		set tickDelay to .1.
		lock throttle to 0.
		updateInfo("PERIAPSIS: " + ship:periapsis + " | APOAPSIS: " + ship:apoapsis).
		set circularized to true.
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