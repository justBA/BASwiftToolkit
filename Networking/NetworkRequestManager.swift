//
//  NetworkRequestManager.swift
//  BASwiftToolkit
//
//  Created by An Nguyen on 08/05/2023.
//

import Foundation
import Combine

enum UploadResponse {
    case progress(percentage: Double)
    case response(data: Data?)
}

enum HTTPMethod: String {
    case get, post, put, delete, patch
    var key: String {
        return self.rawValue.uppercased()
    }
}

enum APIError: Error {
    case badResponse
    case badData
    case statusCode(error: StatusCodeError)
    case invalidURL(urlString: String?)
    case unauthorized
}

extension APIError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .badResponse:
             return "Response was not of expected type."
        case .badData:
            return "Response returned unexpected or invalid data."
        case .statusCode(let error):
            let message = error.message ?? "[\(error.statusCode)]Api failure"
            return "\(message)"
        case .invalidURL(let urlString):
            return "Invalid URL provided.\(urlString ?? "")"
        case .unauthorized:
            return "Unauthorized access denied. Please sign in to continue."
        
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .badResponse:
            return "Response was not of expected type."
        case .badData:
            return "Response returned unexpected or invalid data."
        case .statusCode(let error):
            let message = error.message ?? "Api failure"
            return message
        case .invalidURL(let urlString):
            return "Invalid URL provided.\(urlString ?? "")"
        case .unauthorized:
            return "Unauthorized access denied. Please sign in to continue."
        
        }
    }
}

struct StatusCodeError {
    let statusCode: Int
    var title: String?
    var message: String?
    init(statusCode: Int, data: Data?) {
        self.statusCode = statusCode
        let data = data ?? Data()
        if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
            if let msg = json?["message"] as? String, msg != "" {
                self.message = msg
                
            } else if let msgJson = json?["message"] as? [String: String] {
                self.message = msgJson["message"]
            
            } else if let msgJsons = json?["message"] as? [[String: String]], msgJsons.count > 0 {
                self.message = msgJsons[0]["message"]
            
            }
        }
       
        
        self.title = ""
    }
}

class NetworkRequestManager {
    private let session: URLSession
    init(session: URLSession) {
        self.session = session
    }
    private func tryMapApiErrors(_ output: URLSession.DataTaskPublisher.Output) throws -> Data {
        guard let response = output.response as? HTTPURLResponse else {
            throw APIError.badResponse
        }
        switch response.statusCode {
           
        case 200..<300:
            // Success
            break
        case 401:
            throw APIError.unauthorized
        default:
            print("response.statusCode: \(response.statusCode)")
            throw APIError.statusCode(error: StatusCodeError(statusCode: response.statusCode, data: output.data))
        }

        guard !output.data.isEmpty else {
            throw APIError.badData
        }
        return output.data
    }
}

extension NetworkRequestManager {
    func request(_ urlRequest: URLRequest, debugOutput: Bool = false) -> AnyPublisher<Data, Error> {
        print(urlRequest.cURL())

        return session
            .dataTaskPublisher(for: urlRequest)
            .tryMap(tryMapApiErrors)
            .eraseToAnyPublisher()
    }
    func request<T>(_ urlRequest: URLRequest, decoder: JSONDecoder? = nil, debugOutput: Bool = false) ->
        AnyPublisher<T, Error> where T: Decodable {
            print(urlRequest.cURL())
        let decoder = decoder ?? JSONDecoder()
        return self
            .request(urlRequest, debugOutput: debugOutput)
            .decode(type: T.self, decoder: decoder)
            .eraseToAnyPublisher()
    }
    func upload<O, T>(_ urlRequest: URLRequest, object: O, encoder: JSONEncoder? = nil, decoder: JSONDecoder? = nil,
                      debugOutput: Bool = false) -> AnyPublisher<T, Error> where O: Codable, T: Decodable {
        do {
            let encoder = encoder ?? JSONEncoder()
            let data = try encoder.encode(object)
            if debugOutput {
                NetworkRequestManager.debugOutputJsonDataPrettyPrinted(data)
            }
            var urlRequest: URLRequest = urlRequest
            urlRequest.httpBody = data
            return self
                .request(urlRequest, decoder: decoder, debugOutput: debugOutput)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }
    
    func uploadFile(_ urlRequest: URLRequest) -> AnyPublisher<UploadResponse, Error> {
        print(urlRequest.cURL())
        let subject: PassthroughSubject<UploadResponse, Error> = .init()
        
        let task: URLSessionDataTask = self.session.dataTask(with: urlRequest) {   dataResponse, response, error in
            if let error = error {
                subject.send(completion: .failure(error))
                return
            }
            if (response as? HTTPURLResponse)?.statusCode == 200 ||
                (response as? HTTPURLResponse)?.statusCode == 201 {
                subject.send(.response(data: dataResponse))
                return
            }
            subject.send(.response(data: nil))
        }
        task.resume()
        return subject.eraseToAnyPublisher()
    }

}

extension NetworkRequestManager {
    private static func debugOutputJsonDataPrettyPrinted(_ data: Data?) {
        #if DEBUG
        print("\n###")
        print("Json Data    :")
        if let data = data,
            let jsonObj = try? JSONSerialization.jsonObject(with: data, options: []),
            let jsonData = try? JSONSerialization.data(withJSONObject: jsonObj, options: [.prettyPrinted]),
            let jsonString = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue) {
            print(jsonString)
        } else {
            print("{ nil }")
            if let data = data, let dataString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
                print("Data String: ")
                print(dataString)
            }
        }
        print("###\n")
        #endif
    }
}
