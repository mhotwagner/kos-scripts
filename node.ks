clearscreen.

set thrust to ship:maxThrust.
set accel to thrust / ship:mass.
set burnTime to nextnode:deltav:mag / accel.

set targetSteering to nextnode:deltav.
set targetThrottle to 0.

lock steering to targetSteering.
lock throttle to targetThrottle.

run node1_display.

set state_init to "INITIALIZING".
set state_coasting to "COASTING".
set state_preBurn to "PRE BURN".
set state_burn to "BURN".
set state_finalize to "FINALIZE".
set state_complete to "MANEUVER COMPLETE".
set state to state_init.

set initalDv to nextnode:deltav.
set once to false.
set delayTick to .1.

set states to lexicon().
states:add(state_init, {
	updateInfo("Orienting from " + round(vang(nextnode:deltav, ship:facing:vector)) + "°").
	updateDisplay().
	sas off.
	lock steering to targetSteering.
    if vang(nextnode:deltav, ship:facing:vector) < 0.25 {
		set state to state_coasting.
		set once to false.
	}
}).
states:add(state_coasting, {
	if not once { 
		updateInfo("Drifting through space...").
		set once to true. set delayTick to 1.
	}
	if nextnode:eta <= (burnTime / 2) + 10 {
		set state to state_preBurn.
		set delayTick to .1. set once to false.
	}
}).
states:add(state_preBurn, {
	if not once {
		set once to true.
	}
	updateInfo("Burn in " + round(nextnode:eta - round(burnTime / 2))).
	if nextnode:eta <= burnTime / 2 {
		set state to state_burn.
		set once to false.
	}
}).
states:add(state_burn, {
	if not once {
		//updateInfo("Burning!").
		set delayTick to .01.
		set once to true.
	}
	set targetSteering to nextnode:deltav.
	set accel to thrust / ship:mass.
	set targetThrottle to min(1, nextnode:deltav:mag / accel).

	if nextnode:deltav:mag < 1 {
		//lock throttle to 0.
		set state to state_finalize.
		set once to false.
	}
	updateInfo(vdot(initalDv, nextnode:deltav)).
}).
states:add(state_finalize, {
	if not once {
		updateInfo("Finishing touches").
		set once to true.
		set targetThrottle to .01.
	}
	set targetSteering to nextnode:deltav.
	if vdot(initalDv, nextnode:deltav) < 0 {
		updateInfo("Burn complete!").
		set state to state_complete.
		lock throttle to 0.
		unlock steering.
		unlock throttle.
		set delayTick to 0.1.
		set once to false.
	}
}).


until state = state_complete {
	states[state]().
	updateDisplay().
	wait delayTick.
}