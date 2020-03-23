// CREATED BY HANS SCHÜLEIN

// PRELAUNCH
SET landingpad TO SHIP:GEOPOSITION.
SET controllerheight TO SHIP:ALTITUDE - landingpad:TERRAINHEIGHT.
LOCK h_d TO SHIP:ALTITUDE - landingpad:TERRAINHEIGHT - controllerheight.


// COUNTDOWN
FROM {LOCAL countdown is 3.} UNTIL countdown = 0 STEP {SET countdown TO countdown - 1.} DO {
    PRINT countdown.
    WAIT 1.
}


// LAUNCH
LOCK THROTTLE TO 1.
LOCK STEERING TO UP.
STAGE.
PRINT("LAUNCH").


// ASCENT
WAIT 4.
LOCK THROTTLE TO 0.
PRINT("SHUTDOWN").
WAIT UNTIL SHIP:VERTICALSPEED < 0.
PRINT("APOAPSIS").


// "DUMB" SUICIDE BURN
WAIT UNTIL h_d + SHIP:VERTICALSPEED/CONFIG:IPU < 0.5 * ( SHIP:VERTICALSPEED ^ 2 / (SHIP:MAXTHRUST / SHIP:MASS - 9.81)).
PRINT("SUICIDE BURN IGNITION").
RCS ON.
LOCK THROTTLE TO 1.
LOCK STEERING TO UP.
IF NOT GEAR { TOGGLE GEAR.}


// TOUCHDOWN
WAIT UNTIL SHIP:VERTICALSPEED > 0.
PRINT("TOUCHDOWN").
PRINT(" ").
LOCK THROTTLE TO 0.
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
RCS OFF.