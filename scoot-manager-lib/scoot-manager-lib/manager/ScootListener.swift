//
//  ScootListener.swift
//  scoot-manager
//
//  Created by UZU on 4/9/19.
//  Copyright © 2019 Ammar Tinwala. All rights reserved.
//

import Foundation

protocol ScootListener
{
    func onConnected()
    
    func onDisconnected()
    
    func onDisposed()
    
    func onConnectionFailed()
    
    func onError(e: String)
}
