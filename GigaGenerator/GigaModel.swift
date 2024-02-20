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
  
  let client: GigaClient
  
  var prompt = ""
  var fetchPhase = FetchPhase.initial
  
  init(apiKey: String) {
    self.client = .init(apiKey: apiKey)
  }
  
  @MainActor
  func generateImage() async {
    self.fetchPhase = .loading
    do {
      let fileId = try await client.generateImageId(prompt: prompt)
      
//      let data = client.getFileContent(path: .init(fileId: id), headers: .init(accept: .init(arrayLiteral: .init(contentType: .jpeg))))
//      let (data, _) = try await URLSession.shared.data(from: URL(string: fileId)!)
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
