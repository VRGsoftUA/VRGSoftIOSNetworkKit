//
//  SMGateway.swift
//  VRGSoftIOSNetworkKit
//
//  Created by OLEKSANDR SEMENIUK on 7/17/18.
//  Copyright © 2020 VRG Soft. All rights reserved.
//

import Alamofire

public protocol SMGateway: SMGatewayRequestDelegate {
    
    var gatewayConfigurator: SMGatewayConfigurator { get }
    
    func adapter(for request: SMGatewayRequest) -> SMRequestAdapter
    func retrier(for request: SMGatewayRequest) -> SMRequestRetrier
    
    func defaultFailureBlockFor(request aRequest: SMGatewayRequest) -> SMGatewayRequestResponseBlock
}

public extension SMGateway {
    
    var session: Session {
        return SMSession.shared
    }
    
    
    // MARK: - SMGateway
    
    var gatewayConfigurator: SMGatewayConfigurator {
        
        let configurator: SMGatewayConfigurator = SMGatewayConfigurator.shared
        
        return configurator
    }
    
    func adapter(for request: SMGatewayRequest) -> SMRequestAdapter {
        
        let adapter: SMRequestAdapter = SMRequestAdapter(request: request)
        
        return adapter
    }
    
    func retrier(for request: SMGatewayRequest) -> SMRequestRetrier {
        
        let retrier: SMRequestRetrier = SMRequestRetrier(request: request)
        
        return retrier
    }
    
    func defaultFailureBlockFor(request aRequest: SMGatewayRequest) -> SMGatewayRequestResponseBlock {
        
        func result(data: DataRequest, responseObject: AFDataResponse<Any>) -> SMResponse {
            
            let isCanceled: Bool = {
                
                let result: Bool
                
                if case let .sessionTaskFailed(error): AFError? = responseObject.error,
                    (error as NSError).code == NSURLErrorCancelled {
                    result = true
                } else if responseObject.error?.isExplicitlyCancelledError == true {
                    result = true
                } else {
                    result = false
                }
                
                return result
            }()
            
            let response: SMResponse = SMResponse()
            response.isCancelled = isCanceled
            response.isSuccess = false
            response.textMessage = responseObject.error?.localizedDescription
            response.error = responseObject.error
            
            return response
        }
        
        return result
    }
    
    
    // MARK: Create requests
    
    func request(type: HTTPMethod,
                 path: String,
                 parameters: [String: AnyObject]? = nil,
                 successBlock: @escaping SMGatewayRequestResponseBlock) -> SMGatewayRequest {
        
        let result: SMGatewayRequest = SMGatewayRequest.init(session: session, type: type, delegate: self)
        
        result.path = path
        
        if let parameters: [String: AnyObject] = parameters {
            
            result.parameters = parameters
        }
        
        let failureBlock: SMGatewayRequestResponseBlock = defaultFailureBlockFor(request: result)
        
        result.setup(successBlock: successBlock, failureBlock: failureBlock)
        
        return result
    }

    func request(type: HTTPMethod,
                 path: String,
                 parameters: [String: AnyObject]? = nil,
                 successParserBlock: @escaping SMGatewayRequestSuccessParserBlock) -> SMGatewayRequest {
        
        let result: SMGatewayRequest = SMGatewayRequest.init(session: session, type: type, delegate: self)
        
        result.path = path
        
        if let parameters: [String: AnyObject] = parameters {
            
            result.parameters = parameters
        }
        
        let failureBlock: SMGatewayRequestResponseBlock = defaultFailureBlockFor(request: result)
        
        result.setup(successParserBlock: successParserBlock, failureBlock: failureBlock)
        
        return result
    }

    func uploadRequest(type: HTTPMethod = .post,
                       path: String,
                       constructingBlock: @escaping SMConstructingMultipartFormDataBlock,
                       progressHandler: SMProgressHandler? = nil,
                       successBlock: @escaping SMGatewayRequestResponseBlock) -> SMGatewayRequestMultipart {
        
        let result: SMGatewayRequestMultipart = SMGatewayRequestMultipart(session: session, type: type, constructingBlock: constructingBlock, progressHandler: progressHandler, delegate: self)
        
        result.path = path
        
        let failureBlock: SMGatewayRequestResponseBlock = defaultFailureBlockFor(request: result)
        
        result.setup(successBlock: successBlock, failureBlock: failureBlock)
        
        return result
    }
    
    
    // MARK: - SMGatewayRequestDelegate
    
    func baseUrl(for request: SMGatewayRequest) -> URL? {
        
        let result: URL? = gatewayConfigurator.baseUrl
        
        return result
    }
    
    func defaultParameters(for request: SMGatewayRequest) -> [String: AnyObject] {
        
        let result: [String: AnyObject] = gatewayConfigurator.defaultParameters
        
        return result
    }
    
    func defaultHeaders(for request: SMGatewayRequest) -> [String: String] {
        
        let result: [String: String] = gatewayConfigurator.defaultHeaders
        
        return result
    }
    
    func isInternetReachable(for request: SMGatewayRequest) -> Bool {
        
        let result: Bool = gatewayConfigurator.isInternetReachable
        
        return result
    }
    
    func acceptableStatusCodes(for request: SMGatewayRequest) -> [Int]? {
        
        return nil
    }
    
    func acceptableContentTypes(for request: SMGatewayRequest) -> [String]? {
        
        return nil
    }
    
    func interceptor(for request: SMGatewayRequest) -> SMRequestInterceptor {
        
        let adapter: SMRequestAdapter = self.adapter(for: request)
        let retrier: SMRequestRetrier = self.retrier(for: request)
        
        let interceptor: SMRequestInterceptor = SMRequestInterceptor(adapter: adapter, retrier: retrier)
        
        return interceptor
    }
}
