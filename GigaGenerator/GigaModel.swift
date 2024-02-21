//
//  GigaModel.swift
//  GigaGenerator
//
//  Created by Ляхевич Александр Олегович on 17.02.2024.
//

import Foundation
import Observation
import SwiftUI

@Observable
class GigaModel {
  
  var client: GigaClient
  
  var prompt: String = ""
  var fetchPhase = FetchPhase.initial
  
  init(apiKey: String) {
    self.client = .init(apiKey: apiKey)
  }
  
  @MainActor
  func generateImage() async {
    self.fetchPhase = .loading
//    let expiresAt: TimeInterval = 1708499130720
    //     Повторное выполнение функции после истечения времени expiresAt
//    DispatchQueue.global().asyncAfter(deadline: .now() + expiresAt) {
//      _Concurrency.Task {
        await client.makeOAuthRequest()
        self.client = .init(apiKey: ProcessInfo.processInfo.environment["BearerKey"] ?? "")
//      }
//    }
    do {
      let fileId = try await client.generateImageId(prompt: "Сгенерируй изображение \(prompt)")
      
      guard let image = try await client.getFileContent(fileId: fileId) else {
        self.fetchPhase = .failure("failed to download image")
        return
      }
      self.fetchPhase = .success(Image(uiImage: image))
    } catch {
      self.fetchPhase = .failure(error.localizedDescription)
    }
  }
  }


enum FetchPhase: Equatable {
    case initial
    case loading
    case success(Image)
    case failure(String)
}
