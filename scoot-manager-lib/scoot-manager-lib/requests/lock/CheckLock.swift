//
//  CheckLock.swift
//  test-ryde-scooter
//
//  Created by Mufaddal Gulshan on 16/03/19.
//  Copyright © 2019 Ammar Tinwala. All rights reserved.
//

import Foundation

class CheckLock: RequestProtocol {
    var delay: Int = 100
    var requestBit = "B2"
    var requestType = RequestType.LOCK

    var requestString: String {
        get {
            return NbMessage()
                .setDirection(NbCommands.MASTER_TO_M365)
                .setRW(NbCommands.READ)
                .setPosition(0xB2)
                .setPayload(0x02)
                .build()
        }
    }

    func handleResponse(request: [String]) -> String {
        if(request[6].elementsEqual("02")) {
//            Statistics.setScooterLocked(true);
        }
        else {
//            Statistics.setScooterLocked(false);
        }
        return "";
    }
}
