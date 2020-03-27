//
//  SMSession.swift
//  VRGSoftIOSNetworkKit
//
//  Created by SEMENIUK OLEKSANDR on 26.03.2020.
//  Copyright © 2020 VRGSoft. All rights reserved.
//

import Alamofire

open class SMSession: Session {
    
    public static let shared: SMSession = SMSession(startRequestsImmediately: false)
}
