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