//
//  SMGatewayConfigurator.swift
//  VRGSoftIOSNetworkKit
//
//  Created by OLEKSANDR SEMENIUK on 7/17/18.
//  Copyright © 2020 VRG Soft. All rights reserved.
//

import Alamofire

public protocol SMGatewayConfiguratorProtocol {
    var defaultParameters: [String: AnyObject] { get }
    var defaultHeaders: [String: String] { get }
    var baseUrl: URL? { get }
    var isInternetReachable: Bool { get }
}

open class SMDefaultGatewayConfigurator: SMGatewayConfiguratorProtocol {
    
    public static var shared: SMDefaultGatewayConfigurator = SMDefaultGatewayConfigurator()
    
    open private(set) var defaultParameters: [String: AnyObject] = [:]
    open private(set) var defaultHeaders: [String: String] = [:]
    open private(set) var baseUrl: URL?
    open private(set) var networkReachabilityManager: SMNetworkReachabilityManagerProtocol?
    
    open var isInternetReachable: Bool {
        
        let result: Bool = networkReachabilityManager?.isReachable == true
        
        return result
    }
    
    private init() { }
    
    open func configure(with baseUrl: URL?, networkReachabilityManager: SMNetworkReachabilityManagerProtocol? = nil) {
        
        self.baseUrl = baseUrl
        
        if let networkReachabilityManager: SMNetworkReachabilityManagerProtocol = networkReachabilityManager {
            
            self.networkReachabilityManager = networkReachabilityManager
            
        } else if self.networkReachabilityManager == nil,
            let host: String = baseUrl?.host {
            
            self.networkReachabilityManager = SMDefaultNetworkReachabilityManager(host: host)
        }
        
        self.networkReachabilityManager?.startListening()
    }
    
    open func set(networkReachabilityManager: SMNetworkReachabilityManagerProtocol) {
        self.networkReachabilityManager = networkReachabilityManager
        networkReachabilityManager.startListening()
    }
        
    open func setHTTPHeader(value aValue: String?, key aKey: String) {
        
        defaultHeaders[aKey] = aValue
    }
    
    open func setDefaulParameter(value aValue: AnyObject?, key aKey: String) {
        
        defaultParameters[aKey] = aValue
    }
}
