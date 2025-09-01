// Get the gravity at the ship's altitude
function gravity {
	declare local mu to ship:body:mu.
	declare local radius to (body:radius + ship:altitude).
	declare local g to mu/(radius^2).
	return -g.
}

// Calculate suicide burn altitude for vacuum landings
// Uses orbital mechanics to predict impact velocity
function calculateVacuumBurn {
	declare local parameter __zeroAlt to ROUND(MAX(0.001, ALTITUDE-GEOPOSITION:TERRAINHEIGHT), 3).
	declare local parameter __safetyMargin to 1.01.

	declare local __thrust to ((ship:maxThrust/ship:mass) + gravity()).
	declare local __alt to ((impactV(__zeroAlt)^2)/(2*__thrust)).
	return __safetyMargin * __alt.
}

// Calculate suicide burn altitude for atmospheric landings
// Uses current vertical speed due to atmospheric drag effects
function calculateAtmoBurn {
	declare local parameter safety to 1.01.
	declare local parameter minAltitude to 50.  // minimum safe altitude

	declare local shipMass to ship:mass.
	declare local verticalVelocity to abs(ship:verticalspeed).
	declare local verticalThrust to ((ship:maxThrust/shipMass) + gravity()).
	
	// Protect against division by zero
	if verticalThrust <= 0 {
		return altitude. // If we can't slow down, return current altitude as warning
	}
	
	declare local burnAlt to (verticalVelocity^2)/(2*verticalThrust).
	return max(minAltitude, safety * burnAlt).
}

// Get the impact velocity at a target altitude
function impactV {
	local parameter __targetAlt to ROUND(MAX(0.001, ALTITUDE-GEOPOSITION:TERRAINHEIGHT), 3).
	return getV(__targetAlt).
}

// Get the gravity at a target altitude ... which maybe we haven't been using right?
function getGravity {
	local parameter __targetAlt to ship:altitude.
	declare local mu to ship:body:mu.
	declare local radius to (body:radius + __targetAlt).
	declare local g to mu/(radius^2).
	return g.
}

// Get circular orbital velocity for circular orbit at given altitude
function getCOV {
	local parameter __alt.
	return sqrt(ship:body:mu/(ship:body:radius + __alt)).
}

// Get Velocity at Apoapsis
function getApoV {
	return sqrt(ship:body:mu * ((2/(ship:body:radius + ship:apoapsis))-(1/ship:obt:semimajoraxis))).
}
set getAV to getApoV.

// Get Velocity at Periapsis
function getPeriV {
	return sqrt(ship:body:mu * ((2/(ship:body:radius + ship:periapsis))-(1/ship:obt:semimajoraxis))).
}
set getPV to getPeriV.

// Get Velocity at given altitude in orbit

function getV {
	local parameter __alt.
	return sqrt(ship:body:mu * ((2/(ship:body:radius + __alt))-(1/ship:obt:semimajoraxis))).
}

// Get ship Acceleration
function getA {
	return ship:maxThrust / ship:mass.
}

function autostage {
	if stage:number > 0 {
		set shouldStage to false.
		if maxthrust = 0 { set shouldStage to true. }
		list engines in engines. 
		for engine in engines  { if engine:flameout { set shouldStage to true. break. } }
		if shouldStage { updateInfo("Staging"). stage. wait .5. }
	}
}

function getBurnAlt {
    local parameter __currentAlt is 0.
    local parameter __verticalSpeed is 0.
    local parameter __maxDeceleration is 9.81.  // Default to 1G deceleration
    
    // Calculate the altitude needed to decelerate to 0 m/s
    // Using the equation: h = v² / (2a)
    // where:
    // h = height needed
    // v = current vertical speed
    // a = deceleration rate
    
    local __burnAlt to (__verticalSpeed^2) / (2 * __maxDeceleration).
    
    // Add a safety margin (20%)
    set __burnAlt to __burnAlt * 1.2.
    
    // Ensure we don't return a value higher than current altitude
    if __burnAlt > __currentAlt {
        set __burnAlt to __currentAlt.
    }
    
    return __burnAlt.
}