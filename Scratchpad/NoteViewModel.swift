//
//  NoteViewModel.swift
//  Scratchpad
//
//  Created by Duncan Crawbuck on 2/19/25.
//

import SwiftUI
import SwiftData
import OSLog

/// This class is used to handle the complication that SwiftData doesn't allow unique constraints when syncing in iCloud.
/// It will do it's best to guarantee that there is exactly one NoteModel in the model context for the view,
/// manually resolving duplicates when detected.
/// Hard assumption that the view is using the first NoteModel when sorted by timestamp.
class NoteViewModel: ObservableObject {
    private var modelContext: ModelContext
    private var resolvingDuplicateNoteModels = false
    private let logger = Logger(subsystem: "com.crawbuck.Scratchpad", category: "NoteViewModel")
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        logger.debug("Initializing...")
        refresh()
    }
    
    func refresh() {
        let fetchDescriptor = FetchDescriptor<NoteModel>(sortBy: [SortDescriptor(\.timestamp)])
        let noteModels: [NoteModel]
        do {
            noteModels = try modelContext.fetch(fetchDescriptor)
        }
        catch {
            logger.error("Error fetching note models: \(error)")
            noteModels = []
        }
        logger.debug("Fetched \(noteModels.count) notes")
        handleNoteModels(noteModels)
    }
    
    private func handleNoteModels(_ noteModels: [NoteModel]) {
        if noteModels.isEmpty {
            logger.debug("No notes found. Creating a new one...")
            modelContext.insert(NoteModel())
            try? modelContext.save()
        }
        else if noteModels.count > 1 {
            logger.debug("Detected \(noteModels.count - 1) duplicates. Resolving...")
            Task {
                await self.resolveDuplicateNoteModels(noteModels: noteModels)
            }
        }
        else {
            logger.debug("Exactly one note found. No action needed.")
        }
    }
    
    private func resolveDuplicateNoteModels(noteModels: [NoteModel]) async {
        guard noteModels.count > 1, !resolvingDuplicateNoteModels else {
            logger.debug("No duplicates to resolve or already resolving.")
            return
        }
        resolvingDuplicateNoteModels = true
        logger.debug("Resolving duplicates...")
        
        // Merge all text into first noteModel
        let mergedText: String = noteModels.compactMap { noteModel in
            if !noteModel.text.isEmpty {
                return noteModel.text
            }
            return nil
        }.joined(separator: "\n")
        noteModels[0].text = mergedText
        logger.debug("Merged text from \(noteModels.count) notes into one: \(mergedText)")
        
        // Collect duplicates first to avoid modifying while iterating
        let duplicatesToDelete = Array(noteModels.dropFirst())
        
        // Delete duplicates
        for duplicate in duplicatesToDelete {
            logger.debug("Deleting duplicate note")
            modelContext.delete(duplicate)
        }
        do {
            try modelContext.save()
            logger.debug("Duplicates resolved. Remaining notes: 1")
        }
        catch {
            logger.error("Error saving model context: \(error)")
        }
        
        resolvingDuplicateNoteModels = false
    }
}
