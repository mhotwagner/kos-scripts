// ssto rocket launcher

DECLARE PARAMETER orbitAltKm IS 100.
SET orbitAlt TO orbitAltKm * 1000.

sas off.
lock throttle to 0.
clearscreen.


set orbiting to false.
set stateNames to list(
	"Pre-Launch",
	"Launch",
	"Pad roll",
	"Climb to 2km",
	"Turn to 10km",
	"Climb to 18km",
	"Turn to 40km",
	"Prepare to coast",
	"Adjust apoapsis",
	"Coast to space",
	"Pepare to circularize",
	"Ciruclarize",
	"Orbit"
).
set state to 0.
set targetPitch to 90.
set once to false.

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
	print "+--------------------------------------+" at (0,9).
}

function clearInfo {
	print "|                                      |" at (0,10).
	print "+--------------------------------------+" at (0,11).
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
	print "| APOAPSIS:  " + round(ship:apoapsis) + "m" at(0,7).
	print "| PERIAPSIS: " + round(ship:periapsis) + "m" at(0,8).
	print "+--------------------------------------+" at (0,9).

}

function updateInfo {
	parameter message is "".
	clearInfo().
	print "| INFO: " + message at (0,10).
	print "+--------------------------------------+" at (0,11).

}

function updateHeading {
	set targetHeading to heading(90, targetPitch).
	lock steering to targetHeading.
}

updateDisplay().

from { local countdown is 5. } until countdown = 0 step { set countdown to countdown - 1. } do {
	updateInfo("Launching to " + orbitAlt + "m orbit in " + countdown).
	wait 1.
}


set states to list(
	{ // 0: pre-launch
		set throttle to 1.0.
		set steering to up.
		set targetPitch to 90.
		updateHeading().
		set state to 1.
	}, { // 1: launch
		updateInfo("Launching").
		stage.
		set state to 2.
	}, { // 2: pad roll
		if ship:altitude > 100 {
			updateInfo("Rolling away from pad").
			set targetPitch to 85.
			updateHeading().
			set state to 3.
		}

	}, { // 3: climb to 2km
		if not once and ship:altitude > 200 {
			set once to true.
			updateInfo("Climbing to 2km").
		}
		if ship:ALTITUDE > 2000 {
			set state to 4.
			set once to false.
		}
	}, { // 4: turn to 10km
		if not once {
			set once to true.
			updateInfo("Turning to 45 degrees at 10km").
		}
		set targetPitch to min(85, round(90 - (alt:radar/10000 * 45))).
		updateHeading().
		if ship:altitude > 5000 {
			updateInfo("Throttling back through max q").
			lock throttle to .7.
		}
		if ship:altitude > 10000 {
			updateInfo("Throttling up").
			lock throttle to 1.
			set state to 5.
			set once to false.
		}
	}, { // 5: climb to 18km
		if not once and ship:altitude > 11000 {
			set once to true.
			updateInfo("Climbing to 18km").
		}
		set targetPitch to 45.
		updateHeading().
		if ship:altitude > 18000 {
			set state to 6.
			set once to false.
		}
	}, { // 6: turn to 45km
		if not once {
			set once to true.
			updateInfo("Turning to 5 degrees at 45km").
		}
		set targetPitch TO max(5, round(45 - ((alt:radar-18000)/(45000-18000) * 45))).
		updateHeading().
		if ship:apoapsis > orbitAlt * .95 {
			lock throttle to .25.
		}
		if ship:apoapsis > orbitAlt * .995 {
			lock throttle to .05.
		}
		if ship:apoapsis > orbitAlt {
			set state to 7.
			set once to false.
		}
	},{ // 7: Prepare to coast
		updateInfo("Peparing to coast").
		lock throttle to 0.
		wait 1.
		set targetPitch to 3.
		updateHeading().
		wait 3.
		set state to 9.
	}, { // 8: Adjust apoapsis
		if not once {
			set once to true.
			updateInfo("Adjusting apoapsis").
			lock throttle to .1.
		}
		if ship:apoapsis > orbitAlt * 1.002 { // time to coast
			lock throttle to 0.
			set state to 9.
			set once to false.
		}
	}, { // 9: Coast to apo
		updateHeading().
		if not once {
			set once to true.
			updateInfo("Coasting to space").
			//set warp to 3.
		}
		if ship:apoapsis < orbitAlt * .999 { // need to adjust apo
			//set warp to 0.
			set state to 8.
			set once to false.
		}
		if ship:altitude > 70000 {
			set state to 10.
			set 
		}
		if eta:apoapsis < 30 { // almost there!
			//set warp to 0.
			set state to 10.
			set once to false.
		}
	}, { // 10: Prepare to Circularize
		if not once {
			set once to true.
			updateInfo("Preparing to circularize").
			set targetPitch to 0.
			updateHeading().
		}
		if eta:apoapsis < 10 {
			updateInfo("Circularizing").
			lock throttle to 1.
			set state to 11.
		}
	}, { // 11: Circularize
		updateHeading().
		if ship:periapsis > orbitAlt * .75 { lock throttle to .1. }
		if ship:periapsis > orbitAlt * .95 { lock throttle to .05. }
		if ship:periapsis > orbitAlt * .98 { set state to 12. }
	}, { // 12: Orbit!
		lock throttle to 0.
		updateInfo("Orbiting!").
		set orbiting to true.
	}
).


UNTIL orbiting {
	states[state]().
	updateDisplay().
	wait 0.1.
}

// shutdown systems
panels on.
lights on.
unlock steering.
unlock throttle.
sas on.