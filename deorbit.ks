clearscreen.

declare parameter targetPeriapsis to 0.

set targetSteering to ship:retrograde.
set targetThrottle to 0.

lock steering to targetSteering.
lock throttle to targetThrottle.

run deorbit_display(targetPeriapsis).

set state_init to "INITIALIZE".
set state_burn to "BURN".
set state_complete to "COMPLETE".
set state to state_init.

set once to false.
set delayTick to .1.

set states to lexicon().
states:add(state_init, {
	updateInfo("Orienting from " + round(vang(ship:retrograde:forevector, ship:facing:vector)) + "°").
	updateDisplay().
	sas off.
	set targetSteering to ship:retrograde.
    if vang(ship:retrograde:forevector, ship:facing:vector) < 0.25 {
		set state to state_burn.
		set once to false.
	}
}).
states:add(state_burn, {
	if not once {
		updateInfo("Dropping periapsis").
		set delayTick to .01.
		set once to true.
	}
	if ship:periapsis < targetPeriapsis {
		set once to false.
		set state to state_complete.
		updateInfo("Deborbit burn complete").
	} else if ship:periapsis < (targetPeriapsis * 1.1) {
		set targetThrottle to .05.
	} else {
		set targetThrottle to 1.
	}
}).

until state = state_complete {
	states[state]().
	updateDisplay().
	wait delayTick.
}

unlock steering.
unlock throttle.