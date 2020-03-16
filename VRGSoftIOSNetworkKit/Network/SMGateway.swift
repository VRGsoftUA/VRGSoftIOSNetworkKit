//
//  SMGateway.swift
//  VRGSoftIOSNetworkKit
//
//  Created by OLEKSANDR SEMENIUK on 7/17/18.
//  Copyright © 2020 VRG Soft. All rights reserved.
//

import Alamofire

public protocol SMGatewayProtocol: SMGatewayRequestDelegate {
    
    var defaultGatewayConfigurator: SMGatewayConfiguratorProtocol { get }
    
    func adapter(for request: SMGatewayRequest) -> SMRequestAdapter
    func retrier(for request: SMGatewayRequest) -> SMRequestRetrier
    
    func defaultFailureBlockFor(request aRequest: SMGatewayRequest) -> SMGatewayRequestResponseBlock
    
    
    // MARK: Create requests
    
    func request(type aType: HTTPMethod,
                 path aPath: String,
                 parameters aParameters: [String: AnyObject]?,
                 successBlock aSuccessBlock: @escaping SMGatewayRequestResponseBlock) -> SMGatewayRequest
    func request(type aType: HTTPMethod,
                 path aPath: String,
                 parameters aParameters: [String: AnyObject]?,
                 successParserBlock aSuccessParserBlock: @escaping SMGatewayRequestSuccessParserBlock) -> SMGatewayRequest
    func uploadRequest(type aType: HTTPMethod,
                       path aPath: String,
                       constructingBlock: @escaping SMConstructingMultipartFormDataBlock,
                       successBlock aSuccessBlock: @escaping SMGatewayRequestResponseBlock) -> SMGatewayRequestMultipart
    
}

public extension SMGatewayProtocol {
    
    var defaultGatewayConfigurator: SMGatewayConfiguratorProtocol {
        return SMDefaultGatewayConfigurator.shared
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
            
            let response: SMResponse = SMResponse()
            
            response.isCancelled = (responseObject.error as NSError?)?.code == NSURLErrorCancelled
            response.isSuccess = false
            response.textMessage = responseObject.error?.localizedDescription
            response.error = responseObject.error
            
            return response
        }
        
        return result
    }
    
    
    // MARK: Create requests
    
    func request(type aType: HTTPMethod,
                 path aPath: String,
                 parameters aParameters: [String: AnyObject]? = nil,
                 successBlock aSuccessBlock: @escaping SMGatewayRequestResponseBlock) -> SMGatewayRequest {
        
        let result: SMGatewayRequest = SMGatewayRequest.init(delegate: self, type: aType)
        
        result.path = aPath
        
        if let parameters: [String: AnyObject] = aParameters {
            
            result.parameters = parameters
        }
        
        let failureBlock: SMGatewayRequestResponseBlock = self.defaultFailureBlockFor(request: result)
        
        result.setup(successBlock: aSuccessBlock, failureBlock: failureBlock)
        
        return result
    }

    func request(type aType: HTTPMethod,
                 path aPath: String,
                 parameters aParameters: [String: AnyObject]? = nil,
                 successParserBlock aSuccessParserBlock: @escaping SMGatewayRequestSuccessParserBlock) -> SMGatewayRequest {
        
        let result: SMGatewayRequest = SMGatewayRequest.init(delegate: self, type: aType)
        
        result.path = aPath
        
        if let parameters: [String: AnyObject] = aParameters {
            
            result.parameters = parameters
        }
        
        let failureBlock: SMGatewayRequestResponseBlock = self.defaultFailureBlockFor(request: result)
        
        result.setup(successParserBlock: aSuccessParserBlock, failureBlock: failureBlock)
        
        return result
    }

    func uploadRequest(type aType: HTTPMethod = .post,
                       path aPath: String,
                       constructingBlock: @escaping SMConstructingMultipartFormDataBlock,
                       successBlock aSuccessBlock: @escaping SMGatewayRequestResponseBlock) -> SMGatewayRequestMultipart {
        
        let result: SMGatewayRequestMultipart = SMGatewayRequestMultipart(delegate: self, type: aType, constructingBlock: constructingBlock)
        
        result.path = aPath
        
        let failureBlock: SMGatewayRequestResponseBlock = self.defaultFailureBlockFor(request: result)
        
        result.setup(successBlock: aSuccessBlock, failureBlock: failureBlock)
        
        return result
    }
    
    
    // MARK: - SMGatewayRequestDelegate
    
    func baseUrl(for request: SMGatewayRequest) -> URL? {
        
        let result: URL? = defaultGatewayConfigurator.baseUrl
        
        return result
    }
    
    func defaultParameters(for request: SMGatewayRequest) -> [String: AnyObject] {
        
        let result: [String: AnyObject] = defaultGatewayConfigurator.defaultParameters
        
        return result
    }
    
    func defaultHeaders(for request: SMGatewayRequest) -> [String: String] {
        
        let result: [String: String] = defaultGatewayConfigurator.defaultHeaders
        
        return result
    }
    
    func isInternetReachable(for request: SMGatewayRequest) -> Bool {
        
        let result: Bool = defaultGatewayConfigurator.isInternetReachable
        
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
