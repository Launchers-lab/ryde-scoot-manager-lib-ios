//
//  NbCommands.swift
//  test-ryde-scooter
//
//  Created by Mufaddal Gulshan on 28/03/19.
//  Copyright © 2019 Ammar Tinwala. All rights reserved.
//

enum NbCommands: Int {
    case MASTER_TO_M365 = 0x20
    case MASTER_TO_BATTERY = 0x22
    case READ = 0x01
    case WRITE = 0x03

    func getCommand() -> Int {
        return self.rawValue
    }
}
