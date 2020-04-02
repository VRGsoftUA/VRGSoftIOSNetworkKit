//
//  SMGatewayRequestMultipart.swift
//  VRGSoftIOSNetworkKit
//
//  Created by OLEKSANDR SEMENIUK on 7/17/18.
//  Copyright © 2020 VRG Soft. All rights reserved.
//

import Alamofire

public typealias SMConstructingMultipartFormDataBlock = (MultipartFormData) -> Void
public typealias SMProgressHandler = (Progress) -> Void

open class SMGatewayRequestMultipart: SMGatewayRequest {
    
    open var constructingBlock: SMConstructingMultipartFormDataBlock
    open var progressHandler: SMProgressHandler?
    
    public init(session: Session,
                type: HTTPMethod,
                constructingBlock: @escaping SMConstructingMultipartFormDataBlock,
                progressHandler: SMProgressHandler? = nil,
                delegate: SMGatewayRequestDelegate? = nil) {
        
        self.constructingBlock = constructingBlock
        self.progressHandler = progressHandler
        
        super.init(session: session, type: type, delegate: delegate)
    }
    
    public override init(session: Session, type: HTTPMethod, delegate: SMGatewayRequestDelegate? = nil) {
        fatalError("init(session:type:delegate:) has not been implemented")
    }
    
    override open func getDataRequest() -> DataRequest? {
        
        guard let fullPath: URL = fullPath else {
            return nil
        }
        
        let uploadRequest: UploadRequest = session.upload(multipartFormData: { [weak self] multipartFormData in
            
            self?.constructingBlock(multipartFormData)
            
        }, to: fullPath, method: type, headers: allHeaders)
        
        dataRequest = uploadRequest
        
        dataRequest?.uploadProgress(closure: { [weak self] progres in
            self?.progressHandler?(progres)
        })
        
        dataRequest?.responseJSON(completionHandler: { [weak self] responseObject in
            
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
