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
    open var session: Session
    
    open var dataRequest: DataRequest?
    open var mockResponse: SMMockResponse?
    
    open var retryCount: Int = 0
    open var retryTime: TimeInterval = 0.5
    open var acceptableStatusCodes: [Int]?
    open var acceptableContentTypes: [String]?
    
    open var path: String?
    open var parameters: [String: AnyObject]?
    open var headers: [String: String]?
    open var parameterEncoding: ParameterEncoding?
    
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
    
    public init(session: Session, type: HTTPMethod, delegate: SMGatewayRequestDelegate? = nil) {
        self.session = session
        self.type = type
        self.delegate = delegate
    }
    
    
    // MARK: -
    
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
            
            if let mockResponse: SMMockResponse = mockResponse {
                start(withMockResponse: mockResponse, dataRequest: dataRequest)
            } else {
                dataRequest.resume()
            }
        }
        
        return self
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
    
    
    // MARK: -
    
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
    
    open func getDataRequest() -> DataRequest? {
        
        guard let fullPath: URL = fullPath,
            let parameterEncoding = parameterEncoding(for: type) else { return  nil }
                                        
        let dataRequest: DataRequest = session.request(fullPath,
                                                       method: type,
                                                       parameters: allParams,
                                                       encoding: parameterEncoding,
                                                       headers: allHeaders,
                                                       interceptor: interceptor)
                
        dataRequest.responseJSON(completionHandler: {[weak self] responseObject in
            self?.processResponseObject(responseObject, forDataRequest: dataRequest)
        })
        
        return dataRequest
    }
    
    open func processResponseObject(_ responseObject: AFDataResponse<Any>, forDataRequest dataRequest: DataRequest) {
        
        switch responseObject.result {
        case .success:
            let callBack: SMRequestParserBlock = { [weak self] (aResponse: SMResponse) in
                self?.executeAllResponseBlocks(response: aResponse)
            }
            
            if let successParserBlock: SMGatewayRequestSuccessParserBlock = successParserBlock {
                
                successParserBlock(dataRequest, responseObject, callBack)
            } else if let response: SMResponse = successBlock?(dataRequest, responseObject) {
                
                callBack(response)
            }
        case .failure(let error):
            print("Request failed with error: \(error)")
            executeFailureBlock(responseObject: responseObject)
        }
    }
    
    open func start(withMockResponse mockResponse: SMMockResponse, dataRequest: DataRequest) {
        
        guard let fullPath: URL = fullPath else { return }
        
        let value: Any = mockResponse.value(for: self) as Any
        let error: AFError? = mockResponse.error(for: self)
        let statusCode: Int = mockResponse.statusCode(for: self)
        let delay: TimeInterval = mockResponse.delay(for: self)
        
        let result: AFResult<Any> = Result(value: value, error: error)
        let urlResponse: HTTPURLResponse? = HTTPURLResponse(url: fullPath, statusCode: statusCode, httpVersion: nil, headerFields: nil)
        
        let response: DataResponse = DataResponse(request: dataRequest.request,
                                                  response: urlResponse,
                                                  data: dataRequest.data,
                                                  metrics: dataRequest.metrics,
                                                  serializationDuration: 0,
                                                  result: result)
        
        defaultResponseQueue.asyncAfter(deadline: .now() + delay) {
            self.processResponseObject(response, forDataRequest: dataRequest)
        }
    }
    
    open func executeSuccessBlock(responseObject aResponseObject: AFDataResponse<Any>) {
        
        if let successBlock: SMGatewayRequestResponseBlock = successBlock,
            let dataRequest: DataRequest = dataRequest {
            
            let response: SMResponse = successBlock(dataRequest, aResponseObject)
            
            executeAllResponseBlocks(response: response)
        }
    }
    
    open func executeFailureBlock(responseObject aResponseObject: AFDataResponse<Any>) {
        
        if let failureBlock: SMGatewayRequestResponseBlock = failureBlock,
            let dataRequest: DataRequest = dataRequest {
            
            let response: SMResponse = failureBlock(dataRequest, aResponseObject)
            
            executeAllResponseBlocks(response: response)
        }
    }
    
    open func setup(successBlock aSuccessBlock: @escaping SMGatewayRequestResponseBlock,
                    failureBlock aFailureBlock: @escaping SMGatewayRequestResponseBlock) {
        
        successBlock = aSuccessBlock
        failureBlock = aFailureBlock
    }
    
    open func setup(successParserBlock aSuccessParserBlock: @escaping SMGatewayRequestSuccessParserBlock,
                    failureBlock aFailureBlock: @escaping SMGatewayRequestResponseBlock) {
        
        successParserBlock = aSuccessParserBlock
        failureBlock = aFailureBlock
    }
}

extension Result {
    init(value: Success, error: Failure?) {
        if let error: Failure = error {
            self = .failure(error)
        } else {
            self = .success(value)
        }
    }
}
