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
  
  func extractStringBetweenQuotes(from input: String?) -> String? {
      guard let input = input else {
          return nil
      }

      let pattern = "\"(.*?)\""
      
      if let regex = try? NSRegularExpression(pattern: pattern),
         let match = regex.firstMatch(in: input, range: NSRange(input.startIndex..., in: input)),
         let range = Range(match.range(at: 1), in: input) {
          return String(input[range])
      }
      
      return nil
  }
  
  public func getFileContent(fileId: String) async throws -> UIImage? {
    let url = URL(string: "https://gigachat.devices.sberbank.ru/api/v1/files/\(fileId)/content")!
    
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue("Bearer \(ProcessInfo.processInfo.environment["GIGA_API_KEY"]!)", forHTTPHeaderField: "Authorization")
    
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
        if let imgID = imageResponse.choices?.first?.message?.content, let extractedStrings = extractStringBetweenQuotes(from: imgID) {
          print(extractedStrings)
          return extractedStrings
        } else {
          return ""
        }
        
      default:
        throw "Unknown response"
      }
    default:
      throw "Failed to generate image"
    }
  }
  
}

extension String: LocalizedError {
  public var errorDescription: String? { self }
}
