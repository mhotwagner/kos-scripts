
function hasMainFairing {
	set fl to ship:partsdubbed("mainFairing").
	if fl:length > 0 {
		return true.
	}
	return false.
}

function blowFairing {
	set fairingList to ship:partsdubbed("mainFairing").
	for fairing in fairingList {
		set m to fairing:getmodule("ModuleProceduralFairing").
		m:doevent("deploy").
	}
}

print(hasMainFairing()).
if hasMainFairing() { blowFairing(). }