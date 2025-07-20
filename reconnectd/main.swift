//
//  main.swift
//  reconnectd
//
//  Created by Jason Barrie Morley on 19/07/2025.
//

import Foundation

let daemon = ReconnectDaemon()
daemon.start()
RunLoop.main.run()
