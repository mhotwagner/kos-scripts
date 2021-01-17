function gravity {
	declare local mu to ship:body:mu.
	declare local radius to (body:radius + ship:altitude).
	declare local g to mu/(radius^2).
	return -g.
}

function getBurnAlt {
	declare local parameter safety to 1.01.

	declare local shipMass to ship:mass.
	declare local verticalVelocity to ship:verticalspeed.
	declare local verticalThurst to ((ship:maxThrust/shipMass) + gravity()).
	declare local _burnAlt to (verticalVelocity^2)/(2*verticalThurst).
	return safety * _burnAlt.
}