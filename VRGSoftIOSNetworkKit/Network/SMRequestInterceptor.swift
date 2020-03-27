//
//  SMRequestInterceptor.swift
//  VRGSoftIOSNetworkKit
//
//  Created by OLEKSANDR SEMENIUK on 7/17/18.
//  Copyright © 2020 VRG Soft. All rights reserved.
//

import Alamofire

open class SMRequestInterceptor: RequestInterceptor {
    
    public let adapter: RequestAdapter
    public let retrier: RequestRetrier

    public init(adapter: RequestAdapter, retrier: RequestRetrier) {
        
        self.adapter = adapter
        self.retrier = retrier
    }
    
    public init(request: SMGatewayRequest) {
        
        self.adapter = SMRequestAdapter(request: request)
        self.retrier = SMRequestRetrier(request: request)
    }

    
    // MARK: - RequestInterceptor
    
    open func adapt(_ urlRequest: URLRequest,
                    for session: Session,
                    completion: @escaping (Result<URLRequest, Error>) -> Void) {
        
        adapter.adapt(urlRequest, for: session, completion: completion)
    }
    
    open func retry(_ request: Request,
                    for session: Session,
                    dueTo error: Error,
                    completion: @escaping (RetryResult) -> Void) {
        
        retrier.retry(request, for: session, dueTo: error, completion: completion)
    }
}
