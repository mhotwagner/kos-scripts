// Change orbital inclination
// Parameters:
//   targetInc - target inclination in degrees
//   tolerance - how close we need to get (default 0.1 degrees)

clearscreen.
run utils.
run change_inc_display.

declare parameter targetInc.
declare parameter tolerance to 0.1.

// Initialize display
set state to "INITIALIZING".
set complete to false.
updateDisplay(state, targetInc, calcInclinationDeltaV()).

// Calculate required delta-V for inclination change
// Using simplified vis-viva for circular orbit
function calcInclinationDeltaV {
    local v1 to sqrt(ship:body:mu/(ship:orbit:semimajoraxis)).
    local angleChange to abs(targetInc - ship:orbit:inclination).
    return 2 * v1 * sin(angleChange/2).
}

// Find next node (ascending or descending) that minimizes delta-V
function findNextNode {
    // Check if either node exists
    if (not defined ship:orbit:ascendingnode and not defined ship:orbit:descendingnode) {
        return 999999.  // Return large number if no nodes exist
    }
    
    if abs(targetInc) < abs(ship:orbit:inclination) {
        return choose ship:orbit:descendingnode 
               if defined ship:orbit:descendingnode
               else ship:orbit:ascendingnode.
    } else {
        return choose ship:orbit:ascendingnode 
               if defined ship:orbit:ascendingnode
               else ship:orbit:descendingnode.
    }
}

// Calculate burn time based on current thrust
function calcBurnTime {
    local dV to calcInclinationDeltaV().
    return dV / getA().
}

// Initialize state machine
set states to lexicon().

// Wait for node approach
states:add("INITIALIZING", {
    local dV to calcInclinationDeltaV().
    local burnTime to calcBurnTime().
    local nodeETA to findNextNode().
    
    updateInfo("Delta-V required: " + round(dV,1) + "m/s").
    updateInfo("Burn time: " + round(burnTime,1) + "s").
    updateInfo("Node in: " + round(nodeETA) + "s").
    
    if nodeETA < (burnTime/2 + 60) {
        set state to "PREPARE_BURN".
    }
}).

// Prepare for burn
states:add("PREPARE_BURN", {
    local nodeETA to findNextNode().
    local burnTime to calcBurnTime().
    
    // Point normal/anti-normal based on which node and target inclination
    if ship:orbit:ascendingnode < ship:orbit:descendingnode {
        if targetInc > ship:orbit:inclination {
            set targetSteering to ship:orbit:normal.
        } else {
            set targetSteering to -1 * ship:orbit:normal.
        }
    } else {
        if targetInc > ship:orbit:inclination {
            set targetSteering to -1 * ship:orbit:normal.
        } else {
            set targetSteering to ship:orbit:normal.
        }
    }
    
    lock steering to targetSteering.
    
    if nodeETA <= (burnTime/2) {
        set state to "BURNING".
    }
}).

// Execute burn
states:add("BURNING", {
    if abs(targetInc - ship:orbit:inclination) <= tolerance {
        set state to "COMPLETE".
    } else {
        // Throttle control based on how far we are from target
        local error to abs(targetInc - ship:orbit:inclination).
        if error > 5 {
            lock throttle to 1.
        } else if error > 1 {
            lock throttle to 0.5.
        } else {
            lock throttle to 0.1.
        }
    }
}).

// Cleanup
states:add("COMPLETE", {
    lock throttle to 0.
    unlock steering.
    set complete to true.
}).

// Main loop
until complete {
    states[state]().
    updateDisplay(state, targetInc, calcInclinationDeltaV()).
    wait 0.1.
}
