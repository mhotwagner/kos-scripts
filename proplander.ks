clearscreen.
//15
declare parameter shipHeight to 5.
declare parameter atmoPresent to true.
declare parameter atmoHeight to 70000.
declare parameter terminalHeight to 5000.

//} else	{
//	set atmoHeight to -1.
//	set terminalHeight to 30000.
//}
set landingV to -.1.
set thrust to ship:maxThrust.
set descentCounter to 0.
lock height to alt:radar - shipHeight.
lock descentV to ship:verticalSpeed.
lock deltaV to (landingV - descentV).
lock timeToBurn to ((getBurn() - height) / descentV).
lock neutralThrust to ((ship:mass*g) / thrust).
set delayTick to .1.

set throttleValue to 0.
function updateThrottle { lock throttle to trottleValue. }
set steeringValue to Heading(90, 90).
function updateSteering { lock steering to steeringValue. }

declare state_stationary to "Stationary".
declare state_init to "Initialization".
declare state_tracking to "Tracking".
declare state_tracking_high to "Tracking (High Alt)".
declare state_tracking_low to "Tracking (Low Alt)".
declare state_burn to "Suicide Burn".
declare state_landing to "Landing".
declare state_landed to "Landed".
set state to state_init.

run lander1_utils.
// loads gravity() and getBurn() and load()

run lander1_display.
// loads updateInfo and updateDisplay

set once to false.
set lastAlt to -1.
set stationary to false.
set last to "".

set states to lexicon().
states:add(state_stationary, {
	if not once { updateInfo("Holding"). set once to true. }
	if not stationary { set state to state_tracking. set once to false. }
}).
states:add(state_init, {
	updateInfo("Initializing").
	sas off. rcs off. gear off. brakes off.
	set state to state_tracking.
}).
states:add(state_tracking, {
	if height > atmoHeight { set state to state_tracking_high. }
	else if height > terminalHeight { set state to state_tracking_low. }
	else { set state to state_burn. }
}).
states:add(state_tracking_high, {
	if not once { updateInfo("Falling through space"). set once to true. }
	if height < atmoHeight { set state to state_tracking. set once to false. }
}).
states:add(state_tracking_low, {
	if not once {
		if atmoPresent {
			updateInfo("Falling through atmo").
		}. else { updateInfo("Falling toward the surface"). }
		set once to true.
	}
	if height > atmoHeight or height < terminalHeight + 1 { set state to state_tracking. set once to true. }
}).
states:add(state_burn, {
	if not once { updateInfo(""). set once to true. }
	set steeringValue to srfretrograde.
	if height < getBurn() - descentV + 2 {
		updateInfo("Burning").
		set throttleValue to 1.
	} else { set throttleValue to 0. updateInfo("Falling"). }
	if descentV > -15 { set steeringValue to up. }
	if descentV > -1 {
		set delayTick to .01.
		updateInfo("Touching down").
		set state to state_landing.
		set once to false.
	}
	lock steering to steeringValue.
	lock throttle to throttleValue.
}).
states:add(state_landing, {
	if not once { gear on. set once to true. }
	local land to false.
	set steeringValue to up.
	set throttleValue to neutralThrust.
	//if deltaV > 0 { set throttleValue to neutralThrust + .1. }
	if deltaV < 0 { set throttleValue to neutralThrust - .1. }
	if height < .5 { set land to true. set throttleValue to 0. }
	lock steering to steeringValue.
	lock throttle to throttleValue.
	if land {
		set state to state_landed.
		set delayTick to .1.
		set once to false. }
}).

until state = state_landed {
	set stationary to lastAlt = height and throttleValue = 0.
	if stationary { set state to state_stationary. }
	set lastAlt to height.

	set g to -gravity().
	
	states[state]().
	
	updateDisplay().
	
	wait delayTick.
}


