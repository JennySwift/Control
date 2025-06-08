//
//  TidepoolController.swift
//  Control
//
//  Created by Jenny Swift on 8/6/2025.
//

import Foundation

class TidepoolController {
        
    public func getData() {
        let password = "vocmyp-4fenmu-najKet"
        guard let encodedPassword = password.data(using: .utf8)?.base64EncodedString() else {return}
        
        print("encoded: \(encodedPassword)")
        let headers = [
          "Authorization": "Basic {jaswift89@gmail.com: \(encodedPassword)}",
          "Content-Type": "application/json"
        ]

        let request = NSMutableURLRequest(url: NSURL(string: "https://int-api.tidepool.org/auth/login")! as URL,
                                                cachePolicy: .useProtocolCachePolicy,
                                            timeoutInterval: 10.0)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers

        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
          if (error != nil) {
            print(error as Any)
          } else {
            let httpResponse = response as? HTTPURLResponse
            print(httpResponse)
          }
        })

        dataTask.resume()
    }
}

