clearscreen.

declare parameter shipHeight to 2.
declare parameter atmoPresent to true.
declare parameter atmoHeight to 70000.
declare parameter terminalHeight to 25000.
 
run utils.

lock surfaceAlt to ROUND(MAX(0.001, GEOPOSITION:TERRAINHEIGHT), 3).
lock shipAlt to ROUND(MAX(0.001, ALTITUDE-GEOPOSITION:TERRAINHEIGHT) - shipHeight, 3).
lock burnAlt to getBurnAlt(surfaceAlt).


set landingV to -.1.
set thrust to ship:maxThrust.
set descentCounter to 0.

lock descentV to ship:verticalSpeed.

lock deltaV to (landingV - descentV).
lock timeToBurn to ((burnAlt - shipAlt) / descentV).
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
declare state_horizontal_burn to "Horizontal Burn".
declare state_landing to "Landing".
declare state_landed to "Landed".
set state to state_init.

run lander1_display.
// loads updateInfo and updateDisplay

set once to false.
set lastAlt to -1.
set stationary to false.
set last to "".

set info to "Initializing...".

set states to lexicon().
states:add(state_stationary, {
	if not once { set info to "Holding". set once to true. }
	if not stationary { set state to state_tracking. set once to false. }
}).
states:add(state_init, {
	set info to "Initializing".
	sas off. rcs off. gear off. brakes off.
	set state to state_tracking.
}).
states:add(state_tracking, {
	if shipAlt > atmoHeight { set state to state_tracking_high. }
	else if shipAlt > terminalHeight { set state to state_tracking_low. }
	else { set state to state_burn. }
}).
states:add(state_tracking_high, {
	if not once { set info to "Falling through space". set once to true. }
	if shipAlt < atmoHeight { set state to state_tracking. set once to false. }
}).
states:add(state_tracking_low, {
	if not once {
		if atmoPresent {
			set info to "Falling through atmo".
		}. else { set info to "Falling toward the surface". }
		set once to true.
	}
	if shipAlt > atmoHeight or shipAlt < terminalHeight + 1 { set state to state_tracking. set once to false. }
}).
states:add(state_burn, {
	if not once { 
		set info to "".
		set once to true.
		//if ship:horizontalSpeed > 1 {
		//	set state to state_horizontal_burn.
		//	set once to false.
		//	return.
		//}.
	}
	set steeringValue to srfretrograde.
	if shipAlt < burnAlt + 2 {
		set info to "Burning".
		set throttleValue to 1.
	} else { set throttleValue to 0. set info to "Falling". }
	if descentV > -15 { set steeringValue to up. }
	if descentV > -1 {
		set delayTick to .01.
		set info to "Touching down".
		set state to state_landing.
		set once to false.
	}
	lock steering to steeringValue.
	lock throttle to throttleValue.
}).
//sates:add(state_horizontal_burn, {
//	if not once {
//		set info to "Nulling out horizontal speed".
//		set once to true.
//	}
//	set steering value to 
//}).
states:add(state_landing, {
	if not once { gear on. set once to true. }
	local land to false.
	set steeringValue to up.
	set throttleValue to neutralThrust.
	//if deltaV > 0 { set throttleValue to neutralThrust + .1. }
	if deltaV < 0 { set throttleValue to neutralThrust - .1. }
	if shipAlt < .5 { set land to true. set throttleValue to 0. }
	lock steering to steeringValue.
	lock throttle to throttleValue.
	if land {
		set state to state_landed.
		set delayTick to .1.
		set once to false. }
}).

until state = state_landed {
	set stationary to lastAlt = shipAlt and throttleValue = 0.
	if stationary { set state to state_stationary. }
	set lastAlt to shipAlt.

	set g to -gravity().

	states[state]().

	updateDisplay(info).

	wait delayTick.
}


