import SwiftUI
import SwiftData

/// Main list of notes with add button and navigation to detail.
struct ContentView: View {
    // SwiftData query provides live updates as the store changes.
    @Query(sort: \.createdAt, order: .reverse) private var notes: [Note]
    @Environment(\.modelContext) private var context

    @State private var showingAdd = false

    var body: some View {
        NavigationStack {
            Group {
                if notes.isEmpty {
                    ContentUnavailableView(
                        "No Notes Yet",
                        systemImage: "note.text",
                        description: Text("Tap the + button to add your first note.")
                    )
                } else {
                    List {
                        ForEach(notes) { note in
                            NavigationLink(value: note) {
                                HStack(spacing: 12) {
                                    if let data = note.photoData, let img = UIImage(data: data) {
                                        Image(uiImage: img)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 48, height: 48)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .accessibilityLabel("Note thumbnail")
                                    } else {
                                        Image(systemName: "photo")
                                            .frame(width: 48, height: 48)
                                    }
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(note.title).font(.headline)
                                        Text(note.detail)
                                            .lineLimit(1)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text(note.createdAt, style: .date)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    context.delete(note)
                                    try? context.save()
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Field Notes")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAdd = true
                    } label: {
                        Label("Add Note", systemImage: "plus.circle.fill")
                    }
                    .accessibilityLabel("Add a new note")
                }
            }
            .navigationDestination(for: Note.self) { note in
                NoteDetailView(note: note)
            }
            .sheet(isPresented: $showingAdd) {
                AddEditNoteView()
            }
        }
    }
}
