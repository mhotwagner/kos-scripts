function gravity {
	declare local mu to ship:body:mu.
	declare local radius to (body:radius + ship:altitude).
	declare local g to mu/(radius^2).
	return -g.
}

function getBurnAlt {
	declare local parameter __zeroAlt to ROUND(MAX(0.001, ALTITUDE-GEOPOSITION:TERRAINHEIGHT), 3).
	declare local parameter __safetyMargin to 1.01.

	declare local __thrust to ((ship:maxThrust/ship:mass) + gravity()).
	declare local __alt to ((impactV(__zeroAlt)^2)/(2*__thrust)).
	return __safetyMargin * __alt.
}


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
	return ship:body:radius * sqrt(getGravity(__alt)/(ship:body:radius + __alt)).
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

// get suicide burn?
function getBurn {
	declare local parameter safety to 1.01.

	declare local shipMass to ship:mass.
	declare local verticalVelocity to ship:verticalspeed.
	declare local verticalThurst to ((ship:maxThrust/shipMass) + gravity()).
	declare local burnAlt to (verticalVelocity^2)/(2*verticalThurst).
	return safety * burnAlt.
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