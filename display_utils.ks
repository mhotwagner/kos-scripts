function __getSpaces {
	local parameter n is 1.
	local s is "".
	for i in range(n) {
		set s to s + " ".
	}
	return s.
}

function __getSpacer {
	local parameter lineLength.
	local s is "+-".
	for i in range(lineLength) {
		set s to s + "-".
	}
	return s + "-+".
}

function __padLine {
	local parameter message.
	local parameter lineLength.
	return __getSpaces(lineLength - message:length).
}

function __center {
	local parameter message.
	local parameter lineLength.
	local prefixLength to ceiling((lineLength - message:Length)/2).
	local suffixLength to floor((lineLength - message:Length)/2). 
	return __getSpaces(prefixLength) + message + __getSpaces(suffixLength).
}

function __printLines {
	local parameter lines.
	local parameter offset is 0.
	from { local i to 0. }
	until i = lines:length
	step { set i to i + 1. }
	do { print lines[i] at (0, i + offset). }
}

function __updateInfo {
	local parameter info.
	local parameter lineLength.
	local parameter offset.
	local parameter padding is 10.
	local lines to list().
	for line in info {
		lines:add("| " + line + __padLine(line, lineLength) + " |").
	}
	lines:add(__getSpacer(lineLength)).
	__printLines(lines, offset).
}



function __updateDisplay {
	local parameter keys.
	local parameter values.
	local parameter title is false.
	local parameter info is list().
	local parameter lineLength is 40.

	if info:isType("String") {
		set info to list(info).
	}

	local infoOffset is 0.

	if (title) {
		set infoOffset to keys:length + 4.
	} else {
		set infoOffset to keys:length + 2.
	}

	//__clearDisplay(keys, title, lineLength).
	//__clearInfo(info, lineLength, infoOffset).

	local lines to list(__getSpacer(lineLength)).
	if title {
		lines:add("| " + __center(title, lineLength) + " |").
		lines:add(__getSpacer(lineLength)).
	}
	from { local i is 0. } until (i > keys:length - 1) step { set i to i + 1. } do {
 		local message to keys[i] + ": " + values[i]. 
		lines:add("| " + message + __padLine(message, lineLength) + " |").
	}
	lines:add(__getSpacer(lineLength)).
	__printLines(lines).
	__updateInfo(info, lineLength, infoOffset).
}













