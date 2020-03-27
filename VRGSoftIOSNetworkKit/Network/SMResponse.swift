//
//  SMResponse.swift
//  VRGSoftIOSNetworkKit
//
//  Created by OLEKSANDR SEMENIUK on 7/17/18.
//  Copyright © 2020 VRG Soft. All rights reserved.
//

open class SMResponse {
    
    open var isSuccess: Bool = false
    open var code: Int?
    open var titleMessage: String?
    open var textMessage: String?
    open var dataDictionary: [String: AnyObject] = [:]
    open var boArray: [AnyObject] = []
    open var error: Error?
    open var isCancelled: Bool = false
    
    public init() { }
}
