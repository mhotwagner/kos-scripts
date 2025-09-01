// Script to deploy all Antennae

declare local parameter ant to "".
declare local parameter dir to "ext".


set parts_list to ship:parts.

set valid_antennas to list("SurfAntenna").
set antennas to list().

for part in parts_list {
    declare local isAntenna to false.   
    for antenna in valid_antennas {
        if part:name = antenna { set isAntenna to true. }
    }
    if isAntenna {
        antennas:add(part).
    }
}

set antennas to ship:partsDubbed("ant").

for antenna in antennas {
    set modules to antenna:modules.
    print("--------------------------------").
    // print(antenna).
    // set ml to antenna:allmodules.
    // for m in ml {
    //     print(m).
    // }
    // set events to antenna:getmodule("ModuleDeployableAntenna"):doevent("activate").
    // set even
    // set el to antenna:getmodule("ModuleDeployableAntenna"):allEvents.
    // for event in el {
    //     print(event).
    // }
    // set actionNames to antenna:allactionnames.
    // print(actionNames).
    antenna:getmodule("ModuleDeployableAntenna"):doevent("toggle antenna").
    // for module in modules {
    //     print(module).
    // }
}
