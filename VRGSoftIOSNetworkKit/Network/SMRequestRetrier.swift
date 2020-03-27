//
//  SMRequestRetrier.swift
//  VRGSoftIOSNetworkKit
//
//  Created by OLEKSANDR SEMENIUK on 7/17/18.
//  Copyright © 2020 VRG Soft. All rights reserved.
//

import Alamofire

open class SMRequestRetrier: RequestRetrier {
    
    public let request: SMGatewayRequest
    public private(set) var retryCount: Int = 0
    
    public init(request: SMGatewayRequest) {
        
        self.request = request
        retryCount = request.retryCount
    }
    
    
    // MARK: - RequestRetrier
    
    public func retry(_ request: Request,
                      for session: Session,
                      dueTo error: Error,
                      completion: @escaping (RetryResult) -> Void) {
        
        if retryCount == 0 || (error as NSError?)?.code == NSURLErrorCancelled {
            
            completion(.doNotRetry)
            
        } else {
            
            completion(.retryWithDelay(self.request.retryTime))
            print("\n\nRETRY", self.request.debugDescription)
        }
    }
}
