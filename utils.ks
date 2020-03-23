function getGravity {
	local parameter targetAlt to ship:altitude.
	declare local mu to ship:body:mu.
	declare local radius to (body:radius + ship:altitude).
	declare local g to mu/(radius^2).
	return g.
}

function getOrbitV {
	local parameter __orbitAlt.
	return ship:body:radius * sqrt(getGravity(__orbitAlt)/(ship:body:radius + __orbitAlt)).
}

function getApoV {
	return sqrt(ship:body:mu * ((2/(ship:body:radius + ship:apoapsis))-(1/ship:obt:semimajoraxis))).
}

function getA {
	return ship:maxThrust / ship:mass.
}

function getBurn {
	declare local parameter safety to 1.01.

	declare local shipMass to ship:mass.
	declare local verticalVelocity to ship:verticalspeed.
	declare local verticalThurst to ((ship:maxThrust/shipMass) + gravity()).
	declare local burnAlt to (verticalVelocity^2)/(2*verticalThurst).
	return safety * burnAlt.
}