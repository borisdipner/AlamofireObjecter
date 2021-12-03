//
//  DataRequest+Codable.swift
//  
//
//  Created by Boris Dipner on 12/3/21.
//

import Foundation
import Alamofire
import ObjectMapper

public extension DataRequest {
    
    @discardableResult
    public func responseObject<T: Decodable>(queue: DispatchQueue = .main,
                                             keyPath: String? = nil,
                                             completionHandler: @escaping (AFDataResponse<T>) -> Void) -> Self {
        
        return responseDecodable(of: T.self,
                                 queue: queue,
                                 completionHandler: completionHandler)
    }
    
    
    @discardableResult
    func responseArrayD<T: Decodable>(queue: DispatchQueue = .main,
                                      completionHandler: @escaping (AFDataResponse<[T]>) -> Void) -> Self {
        
        return responseDecodable(of: Array<T>.self,
                                 queue: queue,
                                 completionHandler: completionHandler)
    }
}
