// ssto rocket launcher

DECLARE PARAMETER orbitAltKm IS 100.
SET orbitAlt TO orbitAltKm * 1000.

sas off.
lock throttle to 0.
clearscreen.


set orbiting to false.
set stateNames to lexicon().
stateNames:add("pre-launch", "Pre-Launch").
stateNames:add("launch", "Launch").
stateNames:add("pad-roll", "Pad roll").
stateNames:add("climb-to-2", "Climb to 2km").
stateNames:add("turn-to-10", "Turn to 10km").
stateNames:add("climb-to-18", "Climb to 18km").
stateNames:add("turn-to-45", "Turn to 40km").
stateNames:add("prepare-to-coast", "Prepare to coast").
stateNames:add("adjust-apo", "Adjust apoapsis").
stateNames:add("coast-to-space", "Coast to space").
stateNames:add("coast-to-apo", "Coast to apo").
stateNames:add("prepare-to-circ", "Pepare to circularize").
stateNames:add("circ", "Ciruclarize").
stateNames:add("orbit", "Orbit").

set state to "pre-launch".
set targetPitch to 90.
set once to false.
set tickDelay to .1.

function cleardisplay {
	print "+--------------------------------------+" at (0,0).
	print "|                                      |" at (0,1).
	print "|                                      |" at (0,2).
	print "|                                      |" at (0,3).
	print "|                                      |" at (0,4).
	print "|                                      |" at (0,5).
	print "+--------------------------------------+" at (0,6).
	print "|                                      |" at (0,7).
	print "|                                      |" at (0,8).
	print "|                                      |" at (0,9).
	print "+--------------------------------------+" at (0,10).
}

function clearInfo {
	print "|                                      |" at (0,11).
	print "+--------------------------------------+" at (0,12).
}


function updateDisplay {
	cleardisplay().
	print "+--------------------------------------+" at (0,0).
	print "| SHIP: " + ship:name at (0,1).
	print "| PHASE: " + stateNames[state] at (0,2).
	print "| PIITCH: " + targetPitch + " degrees" at (0,3).
	print "| VELOCITY: " + round(ship:velocity:surface:mag) + " m/s" at (0,4).
	print "| ALTITUDE: " + round(ship:altitude) + "m" at(0,5).
	print "+--------------------------------------+" at (0,6).
	print "| ORBIT:     " + round(ship:apoapsis) + "m" at(0,7).
	print "| APOAPSIS : " + round(ship:apoapsis) + "m" at(0,8).
	print "| PERIAPSIS: " + round(ship:periapsis) + "m" at(0,9).
	print "+--------------------------------------+" at (0,10).

}

function updateInfo {
	parameter message is "".
	clearInfo().
	print "| INFO: " + message at (0,11).
	print "+--------------------------------------+" at (0,12).
}

function updateHeading {
	set targetHeading to heading(90, targetPitch).
	lock steering to targetHeading.
}

function autostage {
	if stage:number > 0 {
		set shouldStage to false.
		if maxthrust = 0 { print "no thrust". set shouldStage to true. }
		list engines in engines. 
		for engine in engines  { if engine:flameout { print "flameout". set shouldStage to true. break. } }
		if shouldStage { updateInfo("Staging"). stage. wait .5. }
	}
}

set states to lexicon().
states:add("pre-launch", { // 0: pre-launch
		updateDisplay().
		from { local countdown is 5. } until countdown = 0 step { set countdown to countdown - 1. } do {
			updateInfo("Launching to " + orbitAlt + "m orbit in " + countdown).
			wait 1.
		}
		set throttle to 1.0.
		set steering to up.
		set targetPitch to 90.
		updateHeading().
		set state to "launch".
}).
states:add("launch", { updateInfo("Launching"). stage. set state to "pad-roll". }).
states:add("pad-roll", { // 2: pad roll
		if ship:altitude > 100 {
			updateInfo("Rolling away from pad").
			if gear { gear off. }
			set targetPitch to 85.
			updateHeading().
			set state to "climb-to-2".}
}).
states:add("climb-to-2", { // 3: climb to 2km
		autostage().
		if not once and ship:altitude > 200 { set once to true. updateInfo("Climbing to 2km"). }
		if ship:ALTITUDE > 2000 { set state to "turn-to-10". set once to false. }
}).
states:add("turn-to-10", {
		autostage().
		if not once { set once to true. updateInfo("Turning to 45 degrees at 10km"). }
		
		set targetPitch to min(85, round(90 - (alt:radar/10000 * 45))).
		updateHeading().
		
		if ship:altitude > 5000 { updateInfo("Throttling back through max q"). lock throttle to .7. }
		
		if ship:altitude > 10000 {
			updateInfo("Throttling up").
			lock throttle to 1.
			set state to "climb-to-18".
			set once to false.
		}
}).
states:add("climb-to-18", { // 5: climb to 18km
		autostage().
		if not once and ship:altitude > 11000 { set once to true. updateInfo("Climbing to 18km"). }
		
		set targetPitch to 45. updateHeading().
		
		if ship:altitude > 18000 { set state to "turn-to-45". set once to false. }
}).
states:add("turn-to-45", { // 6: turn to 45km
		autostage().
		if not once { set once to true. updateInfo("Turning to 5 degrees at 45km"). }
		
		set targetPitch TO max(5, round(45 - ((alt:radar-18000)/(45000-18000) * 45))).
		updateHeading().
		
		if ship:apoapsis > orbitAlt {
			set state to "prepare-to-coast".
			set once to false.
		}
		else if ship:apoapsis > orbitAlt * .995 { lock throttle to .05. }
		else if ship:apoapsis > orbitAlt * .95 { lock throttle to .25. }
}).
states:add("prepare-to-coast", { // 7: Prepare to coast
		updateInfo("Peparing to coast").
		lock throttle to 0. wait 1.
		set targetPitch to 3.
		updateHeading(). wait 3.
		set state to "coast-to-space".
}).
states:add("adjust-apo", { // 8: Adjust apoapsis
		if not once {
			set once to true.
			updateInfo("Adjusting apoapsis").
			lock throttle to .1.
		}
		if ship:apoapsis > orbitAlt * 1.002 { 
			lock throttle to 0. 
			set state to "coast-to-space".
			set once to false.
		}
}).
states:add("coast-to-space", {
		updateHeading().
		if not once { set once to true. updateInfo("Coasting to space"). }
		if ship:apoapsis < orbitAlt * .999 { set state to "adjust-apo". set once to false. }
		if ship:altitude > 70000 { set state to "coast-to-apo". set once to false. }
}).
states:add("coast-to-apo", {
	if not once { set tickDelay to 1. set once to true. updateInfo("Coasting to apoapsis"). }
	set targetPitch to 0. updateHeading().
	if eta:apoapsis < 20 { set state to "prepare-to-circ". set once to false. }
}).
states:add("prepare-to-circ", { // 10: Prepare to Circularize
		if not once {
			set tickDelay to .1.
			set once to true.
			updateInfo("Preparing to circularize").
		}
		set targetPitch to 0. updateHeading().
		if eta:apoapsis < 10 { set tickDelay to .01. set state to "circ". set once to false. }
}).
states:add("circ", { // 11: Circularize
		if not once {
			set once to true.
			updateInfo("Circularizing").
			lock throttle to 1.
		}
		updateHeading().
		if ship:periapsis > orbitAlt * .75 { lock throttle to .1. }
		if ship:periapsis > orbitAlt * .95 { lock throttle to .05. }
		if ship:periapsis > orbitAlt * .999 { set state to "orbit". set once to false. }
}).
states:add("orbit", { // 12: Orbit!
		set tickDelay to .1.
		lock throttle to 0.
		updateInfo("Orbiting!").
		set orbiting to true.
}).


UNTIL orbiting {
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