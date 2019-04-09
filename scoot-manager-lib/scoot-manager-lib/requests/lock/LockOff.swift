//
//  LockOff.swift
//  test-ryde-scooter
//
//  Created by Mufaddal Gulshan on 28/03/19.
//  Copyright © 2019 Ammar Tinwala. All rights reserved.
//

import Foundation

public class LockOn: RequestProtocol {
    var delay: Int = 100

    var requestString: String = NbMessage()
        .setDirection(NbCommands.MASTER_TO_M365)
        .setRW(NbCommands.WRITE)
        .setPosition(0x70)
        .setPayload(0x0001)
        .build()

    var requestBit: String = "70"

    var requestType: RequestType = RequestType.NOCOUNT

    func handleResponse(request: [String]) -> String {
        return request.description
    }
}
