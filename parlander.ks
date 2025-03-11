clearscreen.

set targetSteering to ship:retrograde.

lock steering to targetSteering.

run parlander_display.

set state_falling to "FALLING".
set state_deplpying to "DEPLOY"
set state_complete to "COMPLETE".
set state to state_init.

set once to false.
set delayTick to .1.

set states to lexicon().
states:add(state_falling,{
	if not once {
		updateInfo("Falling through atmo").
		set delayTick to .01.
		set once to true.
	}
	if alt:radar < 10000 {
		set once to false.
		set state to state_deploying.
	}
}).
states:add(state_deploying, {
	chutessafe on.
	updateInfo("Deploying").
	set state to state_complete.
}).

until state = state_complete {
	states[state]().
	updateDisplay().
	wait delayTick.
}

unlock steering.
unlock throttle.