//
//  RequestProtocol.swift
//  test-ryde-scooter
//
//  Created by Mufaddal Gulshan on 16/03/19.
//  Copyright © 2019 Ammar Tinwala. All rights reserved.
//

import Foundation

protocol RequestProtocol {
    var delay: Int { get set }
    var requestString: String { get }
    var requestBit: String { get set }
    var requestType: RequestType { get set }
    func handleResponse(request: [String]) -> String
}
