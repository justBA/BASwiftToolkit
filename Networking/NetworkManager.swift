//
//  NetworkManager.swift
//  BASwiftToolkit
//
//  Created by An Nguyen on 08/05/2023.
//

import Foundation
import Combine
import Network

class NetworkManager {
    static let shared = NetworkManager()
    private let monitor = NWPathMonitor()
    let queue = DispatchQueue(label: "InternetConnectionMonitor")
    @Published var isNetworkConnection: Bool = false
    
    typealias  HTTPHeaders = [String: String]
    private var additionalHeaders: HTTPHeaders?
    static let kTimeoutInterval: Double = 30.0
    private var headers: HTTPHeaders {
        var headers: HTTPHeaders = [:]
        for header in additionalHeaders ?? [:] {
            headers[header.key] = header.value
        }
        return headers
    }
    let networkRequestManager: NetworkRequestManager
    private var cancellables: Set<AnyCancellable> = []
    private static var sessionConfiguration: URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = kTimeoutInterval
        configuration.timeoutIntervalForResource = kTimeoutInterval
        return configuration
    }

    init(_ session: URLSession? = nil,
         sessionDelegate: URLSessionDelegate? = nil,
         additionalHeaders: HTTPHeaders? = nil) {
        let configuration = NetworkManager.sessionConfiguration
        let delegate = sessionDelegate
        let delegateQueue: OperationQueue? = nil
        let session = session ??
            URLSession(configuration: configuration, delegate: delegate, delegateQueue: delegateQueue)
        self.networkRequestManager = NetworkRequestManager(session: session)
        if additionalHeaders != nil {
            self.additionalHeaders = additionalHeaders
        }
        self.checkNetworkConnection()
    }
    
    func checkNetworkConnection() {
        monitor.pathUpdateHandler = { pathUpdateHandler in
            DispatchQueue.main.async {
                if pathUpdateHandler.status == .satisfied {
                    self.isNetworkConnection = true
                    
                } else {
                    self.isNetworkConnection = false
                }
            }
        }
        
        monitor.start(queue: queue)
    }
    
    func generalDataBody(body: [String: Any]) -> Data? {
        if let dataBody = try? JSONSerialization.data(withJSONObject: body,
                                                      options: .prettyPrinted) {
            if let jsonStr = String(data: dataBody, encoding: .utf8) {
                print( jsonStr)
            }
            return dataBody
        }
        return nil
    }
    
    
    func requestItem(url: URL, method: HTTPMethod, params: [String: Any]? = nil) -> URLRequest {
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = headers
        request.httpMethod = method.key
        if let params = params {
            request.httpBody = generalDataBody(body: params)
        }
        return request
    }
    
    func requestItem(url: URL, method: HTTPMethod, body: Data?) -> URLRequest {
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = headers
        request.httpMethod = method.key
        if let body = body {
            request.httpBody = body
        }
        return request
    }
    
    func requestUploadFile(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = headers
        request.httpMethod = HTTPMethod.post.key
        request.setValue("multipart/form-data", forHTTPHeaderField:  "Content-Type")
        return request
    }
}
