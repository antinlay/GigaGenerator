//
//  ContentView.swift
//  GigaGenerator
//
//  Created by Ляхевич Александр Олегович on 17.02.2024.
//

import SwiftUI

struct ContentView: View {
  @Bindable var vm = GigaModel(apiKey: ProcessInfo.processInfo.environment["GIGA_API_KEY"] ?? "")
  
  var body: some View {
    VStack(spacing: 16) {
      switch vm.fetchPhase {
      case .loading: ProgressView("Requesting to AI")
      case .success(let image):
        image.resizable().scaledToFit()
      case .failure(let error):
        Text(error).foregroundStyle(Color.red)
      default: EmptyView()
      }
      
      TextField("Enter prompt", text: $vm.prompt, prompt: Text("Enter prompt"), axis: .vertical)
        .autocorrectionDisabled()
        .textFieldStyle(.roundedBorder)
        .disabled(vm.fetchPhase == .loading)
      
      Button("Generate Image") {
        Task { await vm.generateImage() }
      }
      .buttonStyle(.borderedProminent)
      .disabled(vm.fetchPhase == .loading || vm.prompt.isEmpty)
      
    }
    .padding()
    .navigationTitle("XCA AIText2Image")
  }
}

#Preview {
    ContentView()
}
