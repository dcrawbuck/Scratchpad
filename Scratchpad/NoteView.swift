//
//  NoteView.swift
//  Scratchpad
//
//  Created by Duncan Crawbuck on 2/19/25.
//

import SwiftUI
import SwiftData

struct NoteView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel: NoteViewModel
    // use query vs. viewModel @published so note models are automatically updated
    // important first note model when sorted by timestamp is the one used
    @Query(sort: \NoteModel.timestamp) private var noteModels: [NoteModel]
    @FocusState private var isTextEditorFocused: Bool
    
    init(modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: NoteViewModel(modelContext: modelContext))
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if let noteModel = noteModels.first {
                    TextEditor(
                        text: Binding(
                            get: {
                                return noteModel.text
                            },
                            set: { newText in
                                noteModel.text = newText
                            }
                        )
                    )
                    .focused($isTextEditorFocused)
                    .onAppear { 
                        isTextEditorFocused = true
                    }
                    .onChange(of: scenePhase) { oldPhase, newPhase in
                        if newPhase == .active {
                            isTextEditorFocused = true
                        }
                    }
                    .font(.system(.body, design: .monospaced))
                }
                else {
                    // not really an intended state, but cover edge case and give view model time to figure it out
                    ProgressView()
                        .onAppear {
                            viewModel.refresh()
                        }
                }
            }
#if os(iOS)
                .scrollContentBackground(.hidden)
                .ignoresSafeArea(.container, edges: .bottom)
                .navigationTitle("Scratchpad")
                .navigationBarTitleDisplayMode(.inline)
#endif
        }
    }
}

#Preview {
    let modelContainer = try! ModelContainer(
        for: NoteModel.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    
    NoteView(modelContext: modelContainer.mainContext)
        .modelContainer(modelContainer)
}
