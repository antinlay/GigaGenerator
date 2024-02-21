//
//  ContentView.swift
//  GigaGenerator
//
//  Created by Ляхевич Александр Олегович on 17.02.2024.
//

import SwiftUI

struct ContentView: View {
  @Bindable var gigaModel = GigaModel(apiKey: ProcessInfo.processInfo.environment["BearerKey"] ?? "")
  
  var body: some View {
    VStack(spacing: 16) {
      switch gigaModel.fetchPhase {
      case .loading: ProgressView("Requesting to AI")
      case .success(let image):
        image.resizable().scaledToFit()
      case .failure(let error):
        Text(error).foregroundStyle(Color.red)
      default: EmptyView()
      }
      TextField("Enter prompt", text: $gigaModel.prompt, prompt: Text("введите промт"), axis: .vertical)
        .textFieldStyle(.roundedBorder)
        .disabled(gigaModel.fetchPhase == .loading)
      
      Button("Сгенерировать изображение") {
        Task { await gigaModel.generateImage() }
      }
      .buttonStyle(.borderedProminent)
      .disabled(gigaModel.fetchPhase == .loading || gigaModel.prompt.isEmpty)      
    }
    .padding()
    .navigationTitle("XCA AIText2Image")
  }
}

#Preview {
    ContentView()
}
