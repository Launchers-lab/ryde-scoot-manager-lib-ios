//
//  NbMessage.swift
//  test-ryde-scooter
//
//  Created by Mufaddal Gulshan on 28/03/19.
//  Copyright © 2019 Ammar Tinwala. All rights reserved.
//
import Foundation

class NbMessage {
    private var msg: [Int]?
    private var direction: Int
    private var rw: Int
    private var position: Int
    private var payload: [Int]?
    private var checksum: Int

    init() {
        direction = 0
        rw = 0
        position = 0
        checksum = 0
    }

    func setDirection(_ drct: NbCommands) -> NbMessage {
        direction = drct.getCommand()
        checksum += direction;

        return self;
    }

    func setRW(_ readOrWrite: NbCommands) -> NbMessage { // read or write
        rw = readOrWrite.getCommand();
        checksum += rw;

        return self;
    }

    func setPosition(_ pos: Int) -> NbMessage {
        position = pos;
        checksum += position;

        return self;
    }

    func setPayload(_ singleByteToSend: Int) -> NbMessage {
        payload = [Int]()
        payload?.append(singleByteToSend)

        checksum += 3
        checksum += singleByteToSend

        return self
    }

    func build() -> String {
        setupHeaders()
        setupBody()
        calculateChecksum()
        return construct();
    }

    func setupHeaders() {
        msg = [Int]()
        msg?.append(0x55)
        msg?.append(0xAA)
    }

    func setupBody() {
        msg?.append(payload?.count ?? 0 + 2)
        msg?.append(direction)
        msg?.append(rw)
        msg?.append(position)

        for i in payload ?? [Int]() {
            msg?.append(i)
        }
    }

    func calculateChecksum() {
        checksum ^= 0xffff
        msg?.append((checksum & 0xff))
        msg?.append(checksum >> 8)
    }

    func construct() -> String {
        return msg?.hexString ?? ""
    }
}

extension Collection where Element == Int {
    var hexString: String {
        return map { String(format: "%02X", $0) }.joined()
    }
}
