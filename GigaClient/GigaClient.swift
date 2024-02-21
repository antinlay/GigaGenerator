//
//  GigaClient.swift
//  GigaGenerator
//
//  Created by Ляхевич Александр Олегович on 17.02.2024.
//
import Foundation
import HTTPTypes
import OpenAPIRuntime
import OpenAPIURLSession
import UIKit

struct AuthMiddleware: ClientMiddleware {
  let apiKey: String

  func intercept(_ request: HTTPTypes.HTTPRequest, body: OpenAPIRuntime.HTTPBody?, baseURL: URL, operationID: String, next: @Sendable (HTTPTypes.HTTPRequest, OpenAPIRuntime.HTTPBody?, URL) async throws -> (HTTPTypes.HTTPResponse, OpenAPIRuntime.HTTPBody?)) async throws -> (HTTPTypes.HTTPResponse, OpenAPIRuntime.HTTPBody?) {
    var request = request
    request.headerFields[.authorization] = "Bearer \(apiKey)"
    return try await next(request, body, baseURL)
  }
}

public struct GigaClient {
  let client: Client
  
  public init(apiKey: String) {
    self.client = Client(
      serverURL: try! Servers.server1(),
      transport: URLSessionTransport(),
      middlewares: [AuthMiddleware(apiKey: apiKey)])
  }
  
  public func getFileContent(fileId: String) async throws -> UIImage? {
    let url = URL(string: "https://gigachat.devices.sberbank.ru/api/v1/files/\(fileId)/content")!
    
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue("Bearer \(getEnvironmentVariable("BearerKey")!)", forHTTPHeaderField: "Authorization")
    
    do {
      let (data, _) = try await URLSession.shared.data(for: request)
      if let image = UIImage(data: data) {
        return image
      } else {
        return nil
      }
    } catch {
      throw error
    }
  }
  
  public func generateImageId(prompt: String) async throws -> String {
    let response = try await client.createChatCompletion(headers: .init(accept: .init(arrayLiteral: .init(contentType: .json))), body: .json(.init(model: "GigaChat", messages: .init(arrayLiteral: .init(role: "user", content: prompt)))))
    
    switch response {
    case .ok(let response):
      switch response.body {
      case .json(let imageResponse) where imageResponse.choices?.first?.message?.content != nil:
        if let imgID = imageResponse.choices?.first?.message?.content, let extractedStrings = imgID.extractStringBetweenQuotes() {
          return extractedStrings
        } else {
          return "is not image"
        }
      default:
        throw "Unknown response"
      }
    default:
      throw "Failed to generate image"
    }
  }
  
}

extension GigaClient {
  private func setEnvironmentVariable(_ key: String, _ value: String) {
    setenv(key, value, 1) // 1 means override existing value
  }
  
  private func getEnvironmentVariable(_ key: String) -> String? {
    guard let value = getenv(key) else {
      return nil
    }
    return String(cString: value)
  }
  
  public func makeOAuthRequest() async {
    let url = URL(string: "https://ngw.devices.sberbank.ru:9443/api/v2/oauth")!
    let scope = "GIGACHAT_API_PERS"
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue(getEnvironmentVariable("RqUID"), forHTTPHeaderField: "RqUID")
    request.setValue("Basic \(getEnvironmentVariable("BasicKey") ?? "")", forHTTPHeaderField: "Authorization")
    
    let postData = "scope=\(scope)".data(using: .utf8)
    request.httpBody = postData
    
    do {
      let (data, _) = try await URLSession.shared.data(for: request)
      if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
         let accessToken = json["access_token"] as? String {
        setEnvironmentVariable("BearerKey", accessToken)
        print(accessToken == ProcessInfo.processInfo.environment["BearerKey"])
      }
    } catch {
      print("Error: \(error)")
    }
  }
}

extension String: LocalizedError {
  public var errorDescription: String? { self }
}

extension String {
  func extractStringBetweenQuotes() -> String? {
    let input = self
    
    let pattern = "\"(.*?)\""
    
    if let regex = try? NSRegularExpression(pattern: pattern),
       let match = regex.firstMatch(in: input, range: NSRange(input.startIndex..., in: input)),
       let range = Range(match.range(at: 1), in: input) {
      return String(input[range])
    }
    
    return nil
  }
}
