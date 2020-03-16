//
//  SMGatewayRequest.swift
//  VRGSoftIOSNetworkKit
//
//  Created by OLEKSANDR SEMENIUK on 7/17/18.
//  Copyright © 2020 VRG Soft. All rights reserved.
//

import Alamofire

public typealias SMGatewayRequestResponseBlock = (DataRequest, AFDataResponse<Any>) -> SMResponse

public typealias SMRequestParserBlock = (SMResponse) -> Void
public typealias SMGatewayRequestSuccessParserBlock = (DataRequest, AFDataResponse<Any>, @escaping SMRequestParserBlock) -> Void

public protocol SMGatewayRequestDelegate: class {
    func baseUrl(for request: SMGatewayRequest) -> URL?
    func isInternetReachable(for request: SMGatewayRequest) -> Bool
    
    func defaultParameters(for request: SMGatewayRequest) -> [String: AnyObject]
    func defaultHeaders(for request: SMGatewayRequest) -> [String: String]
    func acceptableStatusCodes(for request: SMGatewayRequest) -> [Int]?
    func acceptableContentTypes(for request: SMGatewayRequest) -> [String]?
    func interceptor(for request: SMGatewayRequest) -> SMRequestInterceptor?
}

public extension SMGatewayRequestDelegate {
    
    func defaultParameters(for request: SMGatewayRequest) -> [String: AnyObject] {
        return [:]
    }
    
    func defaultHeaders(for request: SMGatewayRequest) -> [String: String] {
        return [:]
    }
    
    func acceptableStatusCodes(for request: SMGatewayRequest) -> [Int]? {
        return nil
    }
    
    func acceptableContentTypes(for request: SMGatewayRequest) -> [String]? {
        return nil
    }
    
    func interceptor(for request: SMGatewayRequest) -> SMRequestInterceptor? {
        return nil
    }
}

open class SMGatewayRequest: SMRequest {
    
    public var debugDescription: String {
        
        var array: [String] = []
        
        array.append("URL - " + (dataRequest?.request?.url?.absoluteString ?? (fullPath?.absoluteString) ?? ""))
        array.append("TYPE - " + type.rawValue)
        array.append("HEADERS - " + allHeaders.description)
        array.append("PARAMS - " + allParams.description)
        
        return  array.joined(separator: "\n") + "\n"
    }
    
    open weak var delegate: SMGatewayRequestDelegate?
    open var type: HTTPMethod
    
    open var dataRequest: DataRequest?
    
    open var retryCount: Int = 0
    open var retryTime: TimeInterval = 0.5
    
    open var acceptableStatusCodes: [Int]?
    open var acceptableContentTypes: [String]?
    
    open var path: String?
   
    open var parameterEncoding: ParameterEncoding?
    
    open var parameters: [String: AnyObject]?
    open var headers: [String: String]?
    
    open var successBlock: SMGatewayRequestResponseBlock?
    open var successParserBlock: SMGatewayRequestSuccessParserBlock?
    open var failureBlock: SMGatewayRequestResponseBlock?
    
    open var printCURLDescription: Bool = true
    
    open var allParams: [String: Any] {
        
        var result: [String: Any] = [:]
        
        if let defaultParameters: [String: AnyObject] = delegate?.defaultParameters(for: self) {
            
            for (key, value): (String, AnyObject) in defaultParameters {
                
                result.updateValue(value, forKey: key)
            }
        }
        
        if let parameters: [String: AnyObject] = parameters {
            
            for (key, value): (String, AnyObject) in parameters {
                
                result.updateValue(value, forKey: key)
            }
        }
        
        return result
    }
    
    open var allHeaders: HTTPHeaders {
        
        var result: HTTPHeaders = HTTPHeaders()
        
        if let defaultHeaders: [String: String] = delegate?.defaultHeaders(for: self) {
            
            for (key, value): (String, String) in defaultHeaders {
                
                result.update(name: key, value: value)
            }
        }
        
        if let headers: [String: String] = headers {
            
            for (key, value): (String, String) in headers {
                
                result.update(name: key, value: value)
            }
        }
        
        return result
    }
    
    open var allAcceptableStatusCodes: [Int]? {
        
        var result: [Int]?
                
        if let acceptableStatusCodes: [Int] = delegate?.acceptableStatusCodes(for: self) {
            
            if result == nil {
                result = []
            }
            
            result?.append(contentsOf: acceptableStatusCodes)
        }
        
        if let acceptableStatusCodes: [Int] = acceptableStatusCodes {
            
            if result == nil {
                result = []
            }
            
            result?.append(contentsOf: acceptableStatusCodes)
        }
        
        return result
    }
    
    open var allAcceptableContentTypes: [String]? {
        
        var result: [String]?
                
        if let acceptableContentTypes: [String] = delegate?.acceptableContentTypes(for: self) {
            
            if result == nil {
                result = []
            }
            
            result?.append(contentsOf: acceptableContentTypes)
        }
        
        if let acceptableContentTypes: [String] = acceptableContentTypes {
            
            if result == nil {
                result = []
            }
            
            result?.append(contentsOf: acceptableContentTypes)
        }
        
        return result
    }
    
    open var fullPath: URL? {
        
        var result: URL?
        
        if let baseUrl: URL = delegate?.baseUrl(for: self) {
            
            result = baseUrl
            
            if let path: String = path {
                result = baseUrl.appendingPathComponent(path)
            }
        } else if let path: String = path {
            
            result = URL(string: path)
        }
        
        return result
    }
    
    open var interceptor: RequestInterceptor? {
        
        let result: RequestInterceptor? = delegate?.interceptor(for: self)
        
        return result
    }
    
    public init(delegate: SMGatewayRequestDelegate?, type: HTTPMethod) {
        self.delegate = delegate
        self.type = type
    }
    
    public init(type: HTTPMethod, path: String, parameters: [String: AnyObject]? = nil, headers: [String: String]? = nil) {
        self.type = type
        self.path = path
        self.parameters = parameters
        self.headers = headers
    }
    
    open func parameterEncoding(for type: HTTPMethod) -> ParameterEncoding? {
        let result: ParameterEncoding?
        
        if let parameterEncoding: ParameterEncoding = parameterEncoding {
            result = parameterEncoding
        } else {
            switch type {
            case .options, .head, .get, .delete:
                result = URLEncoding.default
            case .patch, .post, .put:
                result = JSONEncoding.default
            default:
                result = nil
            }
        }
        
        return result
    }
    
    @discardableResult
    override open func start() -> Self {
        
        if let dataRequest: DataRequest = getDataRequest() {
            
            super.start()
            
            if let acceptableStatusCodes: [Int] = allAcceptableStatusCodes {
                dataRequest.validate(statusCode: acceptableStatusCodes)
            }
            
            if let acceptableContentTypes: [String] = acceptableContentTypes {
                dataRequest.validate(contentType: acceptableContentTypes)
            }
            
            self.dataRequest = dataRequest
            
            print("\n\nSTART", self)
            print(debugDescription)
            
            printCURLIfNeeded()
            
            dataRequest.resume()
        }
        
        return self
    }
    
    func printCURLIfNeeded() {
        if printCURLDescription {
            dataRequest?.cURLDescription(calling: { test in
                print("""
                    \ncURL description \(self)
                    **********************
                    \(test)
                    **********************
                    """)
            })
        }
    }
    
    override open func cancel() {
        
        dataRequest?.cancel()
    }
    
    override open func canExecute() -> Bool {
        
        let result: Bool = delegate?.isInternetReachable(for: self) ?? true
        
        return result
    }
    
    override open func isCancelled() -> Bool {
        
        return dataRequest?.task?.state == .completed
    }
    
    override open func isExecuting() -> Bool {
        
        return dataRequest?.task?.state == .running
    }
    
    override open func isFinished() -> Bool {
        
        return dataRequest?.task?.state == .completed
    }
    
    open func getDataRequest() -> DataRequest? {
        
        guard let fullPath: URL = fullPath,
            let parameterEncoding = parameterEncoding(for: type) else { return  nil }
                                
        let dataRequest: DataRequest = AF.request(fullPath, method: type, parameters: allParams, encoding: parameterEncoding, headers: allHeaders, interceptor: interceptor)
                
        dataRequest.responseJSON(completionHandler: {[weak self] responseObject in
            
            switch responseObject.result {
            case .success:
                let callBack: SMRequestParserBlock = { (aResponse: SMResponse) in
                    if let strongSelf: SMGatewayRequest = self {
                        
                        if strongSelf.executeAllResponseBlocksSync {
                            strongSelf.executeSynchronouslyAllResponseBlocks(response: aResponse)
                        } else {
                            strongSelf.executeAllResponseBlocks(response: aResponse)
                        }
                    }
                }
                
                if let successParserBlock: SMGatewayRequestSuccessParserBlock = self?.successParserBlock {
                    
                    successParserBlock(dataRequest, responseObject, callBack)
                } else {
                    if let response: SMResponse = self?.successBlock?(dataRequest, responseObject) {
                        
                        callBack(response)
                    }
                }
            case .failure(let error):
                print("Request failed with error: \(error)")
                self?.executeFailureBlock(responseObject: responseObject)
            }
        })
        
        return dataRequest
    }
    
    open func executeSuccessBlock(responseObject aResponseObject: AFDataResponse<Any>) {
        
        if let successBlock: SMGatewayRequestResponseBlock = successBlock,
            let dataRequest: DataRequest = dataRequest {
            
            let response: SMResponse = successBlock(dataRequest, aResponseObject)
            
            if executeAllResponseBlocksSync {
                
                executeSynchronouslyAllResponseBlocks(response: response)
            } else {
                
                executeAllResponseBlocks(response: response)
            }
        }
    }
    
    open func executeFailureBlock(responseObject aResponseObject: AFDataResponse<Any>) {
        
        if let failureBlock: SMGatewayRequestResponseBlock = failureBlock,
            let dataRequest: DataRequest = dataRequest {
            
            let response: SMResponse = failureBlock(dataRequest, aResponseObject)
            
            if executeAllResponseBlocksSync {
                
                executeSynchronouslyAllResponseBlocks(response: response)
            } else {
                
                executeAllResponseBlocks(response: response)
            }
        }
    }
    
    open func setup(successBlock aSuccessBlock: @escaping SMGatewayRequestResponseBlock, failureBlock aFailureBlock: @escaping SMGatewayRequestResponseBlock) {
        
        successBlock = aSuccessBlock
        failureBlock = aFailureBlock
    }
    
    open func setup(successParserBlock aSuccessParserBlock: @escaping SMGatewayRequestSuccessParserBlock, failureBlock aFailureBlock: @escaping SMGatewayRequestResponseBlock) {
        
        successParserBlock = aSuccessParserBlock
        failureBlock = aFailureBlock
    }
}
