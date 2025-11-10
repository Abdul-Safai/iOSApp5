import SwiftUI
import SwiftData

struct EditNoteView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Bindable var note: Note

    var body: some View {
        Form {
            TextField("Title", text: $note.title)
            TextField("Note", text: $note.text, axis: .vertical)
                .lineLimit(6, reservesSpace: true)
        }
        .navigationTitle("Edit Note")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    note.updatedAt = .now
                    try? context.save()
                    dismiss()
                }
            }
        }
    }
}
