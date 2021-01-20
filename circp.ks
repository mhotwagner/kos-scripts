clearscreen.

run utils.

sas off.

set orbitAlt to ship:periapsis.
set targetThrottle to 0.
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

set info to list().


run circp_display.

set states to lexicon().
states:add(state_init, {
	set deltaV to getPeriV() - getCOV(ship:periapsis).
	set burnTime to deltaV / getA().
	updateDisplay(info).
	set state to state_coast.
}).
states:add(state_coast, {
	if not once {
		set tickDelay to 1. set once to true.
		set info to list("Coasting to burn").
	}
	if (eta:periapsis - (burnTime / 2)) <  30 {
		set state to state_preBurn. set once to false.
	}
}).
states:add(state_preBurn, {
	set targetHeading to ship:retrograde.
	lock steering to targetHeading.
	if not once {
		set tickDelay to .01.
		set info to list("Preparing to circularize").
		set once to true.
	}

	if (eta:periapsis - (burnTime / 2)) <  0 {
		set tickDelay to .01. set state to state_circ. set once to false.
	}
}).
states:add(state_circ, {
		if not once {
			set once to true.
			set info to list("Circularizing").
			lock throttle to 1.
		}
		if ship:apoapsis > 1 and ship:apoapsis < orbitAlt * 1.1 { lock throttle to .1. }
		if ship:apoapsis > 1 and ship:apoapsis < orbitAlt * 1.05 { lock throttle to .05. }
		if ship:apoapsis > 1 and ship:apoapsis < orbitAlt * 1.001 or ship:periapsis < orbitAlt *.9 {
		  	set state to state_final. set once to false.
	  }
}).
states:add(state_final, {
		set tickDelay to .1.
		lock throttle to 0.
		set info to list("PERI: " + round(ship:periapsis) + " | APO: " + round(ship:apoapsis)).
		set circularized to true.
}).

until circularized {
	states[state]().
	updateDisplay(info).
	wait tickDelay.
}

// shutdown systems
panels on.
lights on.
unlock steering.
unlock throttle.
sas on.