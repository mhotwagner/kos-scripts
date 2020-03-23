// simple launcher

DECLARE MAXALTITUDE TO 5000.
CLEARSCREEN.

PRINT "Counting down...".
FROM {local countdown is 3.} UNTIL countdown = 0 STEP {SET countdown to countdown - 1.} DO {
	PRINT "..." + countdown.
	WAIT 1.
}

LOCK THROTTLE TO 1.0.
LOCK STEERING TO UP.

UNTIL SHIP:MAXTHRUST > 0 {
	WAIT 0.5.
	PRINT "Staging".
	STAGE.
}

WAIT UNTIL SHIP:ALTITUDE > 10.
PRINT "Retracting landing legs".
LEGS OFF.

WAIT UNTIL SHIP:ALTITUDE > MAXALTITUDE.
PRINT "MECO".
LOCK THROTTLE TO 0.

WAIT UNTIL SHIP:VERTICALSPEED < 0.1.
PRINT "Max altitude reached: " + FLOOR(SHIP:ALTITUDE) + " meters".
PRINT "Descending".

WAIT UNTIL SHIP:ALTITUDE < 2000.
PRINT "Deploying chutes".
CHUTES ON.

WAIT UNTIL SHIP:ALTITUDE < 100.
PRINT "Deploying landing legs".
LEGS ON.

WAIT UNTIL SHIP:VELOCITY = 0.
PRINT "Landing sucessful!".

