//
//  SMMockResponse.swift
//  VRGSoftIOSNetworkKit
//
//  Created by SEMENIUK OLEKSANDR on 26.03.2020.
//  Copyright © 2020 VRGSoft. All rights reserved.
//

import Alamofire

public protocol SMMockResponse {
    func value(for request: SMGatewayRequest) -> Any?
    func error(for request: SMGatewayRequest) -> AFError?
    func delay(for request: SMGatewayRequest) -> TimeInterval
    func statusCode(for request: SMGatewayRequest) -> Int
}

open class SMSimplyMockResponse: SMMockResponse {
    
    open var value: Any?
    open var error: AFError?
    open var delay: TimeInterval
    open var statusCode: Int
    
    init(value: Any? = nil, error: Error? = nil, statusCode: Int = 200, delay: TimeInterval = 0.5) {
        
        self.value = value
        self.error = error?.asAFSessionTaskFailedError
        self.statusCode = statusCode
        self.delay = delay
    }
    
    init(value: Any? = nil, error: AFError? = nil, statusCode: Int = 200, delay: TimeInterval = 0.5) {
        
        self.value = value
        self.error = error
        self.statusCode = statusCode
        self.delay = delay
    }
    
    
    // MARK: - SMMockResponse
    
    open func value(for request: SMGatewayRequest) -> Any? {
        
        return value
    }
    
    open func error(for request: SMGatewayRequest) -> AFError? {
        
        return error
    }
    
    open func delay(for request: SMGatewayRequest) -> TimeInterval {
        
        return delay
    }
    
    open func statusCode(for request: SMGatewayRequest) -> Int {
        
        return statusCode
    }
}

public extension Error {
    
    var asAFSessionTaskFailedError: AFError {
        
        return .sessionTaskFailed(error: self)
    }
}
