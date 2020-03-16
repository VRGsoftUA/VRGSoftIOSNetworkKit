//
//  SMGatewayRequestMultipart.swift
//  VRGSoftIOSNetworkKit
//
//  Created by OLEKSANDR SEMENIUK on 7/17/18.
//  Copyright © 2020 VRG Soft. All rights reserved.
//

import Alamofire

public typealias SMConstructingMultipartFormDataBlock = (MultipartFormData) -> Void

open class SMGatewayRequestMultipart: SMGatewayRequest {
    
    open var constructingBlock: SMConstructingMultipartFormDataBlock
    
    public init(delegate: SMGatewayRequestDelegate?,
                type aType: HTTPMethod,
                constructingBlock: @escaping SMConstructingMultipartFormDataBlock) {
        
        self.constructingBlock = constructingBlock
        super.init(delegate: delegate, type: aType)
    }
    
    public init(type: HTTPMethod,
                path: String,
                parameters: [String: AnyObject]? = nil,
                headers: [String: String]? = nil,
                constructingBlock: @escaping SMConstructingMultipartFormDataBlock) {
        
        self.constructingBlock = constructingBlock
        
        super.init(type: type, path: path, parameters: parameters, headers: headers)
        
    }
    
    public override init(delegate: SMGatewayRequestDelegate?, type: HTTPMethod) {
        fatalError("init(delegate:type:) has not been implemented")
    }
    
    override init(type: HTTPMethod,
                  path: String,
                  parameters: [String: AnyObject]? = nil,
                  headers: [String: String]? = nil) {
        fatalError("init(type:path:parameters:headers:) has not been implemented")
        
    }
    
    override open func getDataRequest() -> DataRequest? {
        guard let fullPath: URL = fullPath else {
            return nil
        }
        
        let uploadRequest: UploadRequest = AF.upload(multipartFormData: { multipartFormData in
            
            self.constructingBlock(multipartFormData)
            
        }, to: fullPath, method: type, headers: allHeaders)
        
        self.dataRequest = uploadRequest
        
        self.dataRequest?.responseJSON(completionHandler: {[weak self] responseObject in
            switch responseObject.result {
            case .success:
                self?.executeSuccessBlock(responseObject: responseObject)
            case .failure(let error):
                print("Request failed with error: \(error)")
                self?.executeFailureBlock(responseObject: responseObject)
            }
        })
        
        return uploadRequest
    }
}
