//
//  URLRequest+Extension.swift
//  BASwiftToolkit
//
//  Created by An Nguyen on 08/05/2023.
//

extension URLRequest {
    /// This extension to use to help print the request as cURL to easy debug with postman
    public func cURL(pretty: Bool = false) -> String {
        let newLine = pretty ? "\\\n" : ""
        let method = (pretty ? "--request " : "-X ") + "\(self.httpMethod ?? "GET") \(newLine)"
        let url: String = (pretty ? "--url " : "") + "\'\(self.url?.absoluteString ?? "")\' \(newLine)"
        
        var cURL = "curl "
        var header = ""
        var data: String = ""
        
        if let httpHeaders = self.allHTTPHeaderFields, httpHeaders.keys.count > 0 {
            for (key,value) in httpHeaders {
                header += (pretty ? "--header " : "-H ") + "\'\(key): \(value)\' \(newLine)"
            }
        }
        
        if let bodyData = self.httpBody, let bodyString = String(data: bodyData, encoding: .utf8),  !bodyString.isEmpty {
            data = "--data '\(bodyString)'"
        }
        
        cURL += method + url + header + data
        
        return cURL
    }
    
    mutating func setMultipartFormDataBody(params: [String: (Data, filename: String?, mimetype: String)]) {
       let boundary = UUID().uuidString
       
       self.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
       
       var body = Data()
       for (key, (data, filename, mimeType)) in params {
           body.append("--\(boundary)\r\n")
           
           
           if let filename = filename {
               body.append("Content-Disposition: form-data; name=\"\(key)\"; filename=\"\(filename)\"\r\n")
           }
           else {
               body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n")
           }
           
           body.append("Content-Type: \(mimeType)\r\n\r\n")
           body.append(data)
           body.append("\r\n")
       }
        body.append("--\(boundary)--\r\n")
        self.httpBody = body
        self.setValue(String(body.count), forHTTPHeaderField: "Content-Length")
    }
}

extension Data {
    mutating func append(_ s: String) {
        self.append(s.data(using: .utf8)!)
    }
}
