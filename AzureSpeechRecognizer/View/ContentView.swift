//
//  ContentView.swift
//  AzureSpeechRecognizer
//
//  Created by kazunori.aoki on 2022/07/28.
//

import SwiftUI

struct ContentView: View {

    @StateObject var viewModel = ViewModel()

    var body: some View {
        VStack {
            Button(action: { viewModel.record() }) {
                Text("Record")
                    .font(.largeTitle)
            }
            .padding(.bottom, 20)

            Button(action: { viewModel.stop() }) {
                Text("Stop")
                    .font(.largeTitle)
            }
        }
        .onAppear(perform: viewModel.onAppear)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
