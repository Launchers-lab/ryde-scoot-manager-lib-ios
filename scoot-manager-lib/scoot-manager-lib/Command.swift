//
//  Command.swift
//  test-ryde-scooter
//
//  Created by Mufaddal Gulshan on 28/03/19.
//  Copyright © 2019 Ammar Tinwala. All rights reserved.
//

import Foundation

enum Command: String {
    case lockOn = "Lock On",
        lockOff = "Lock Off",
        cruiseOn = "Cruise On",
        cruiseOff = "Cruise Off",
        lightsOn = "Lights On",
        lightsOff = "Lights Off",
        powerOff = "Power Off",
        speed = "Speed",
        distance = "Distance",
        battery = "Battery",
        checkLock = "Check Lock",
        checkLights = "Check Lights",
        checkCruise = "Check Cruise"

    func val() -> String {
        return self.rawValue
    }
}
