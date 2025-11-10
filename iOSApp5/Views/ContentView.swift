import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Note.updatedAt, order: .reverse) private var notes: [Note]

    @State private var search = ""
    @State private var showAdd = false
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        NavigationStack {
            Group {
                if filtered.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "note.text").font(.system(size: 52))
                        Text("Create your first note").font(.title3).bold()
                        Button { showAdd = true } label: {
                            Label("New Note", systemImage: "plus")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(filtered) { note in
                            NavigationLink(value: note) { NoteRow(note: note) }
                                .swipeActions {
                                    Button(role: .destructive) {
                                        context.delete(note)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .searchable(text: $search)
            .navigationTitle("iOSApp5 Notes")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: { Image(systemName: "plus.circle.fill") }
                }
            }
            .sheet(isPresented: $showAdd) { AddEditNoteView() }
            .navigationDestination(for: Note.self) { note in
                NoteDetailScreen(note: note)
            }
        }
        .sheet(isPresented: .constant(!hasSeenOnboarding)) {
            OnboardingView { hasSeenOnboarding = true }
        }
    }

    private var filtered: [Note] {
        let q = search.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return notes }
        return notes.filter { $0.title.localizedCaseInsensitiveContains(q) || $0.text.localizedCaseInsensitiveContains(q) }
    }
}

struct NoteRow: View {
    let note: Note
    var body: some View {
        HStack(spacing: 12) {
            if let first = note.attachments.first {
                if first.mediaType == "image", let ui = UIImage(data: first.data) {
                    Image(uiImage: ui).resizable().scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else if first.mediaType == "video" {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8).fill(.quaternary)
                        Image(systemName: "video.fill").imageScale(.large)
                    }
                    .frame(width: 44, height: 44)
                } else {
                    placeholderThumb
                }
            } else {
                placeholderThumb
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(note.title).font(.headline)
                Text(note.text).lineLimit(1).foregroundStyle(.secondary)
            }
            Spacer()
            Text(note.updatedAt, style: .time).font(.caption).foregroundStyle(.secondary)
        }
    }

    private var placeholderThumb: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8).fill(.quaternary)
            Image(systemName: "photo").imageScale(.large)
        }
        .frame(width: 44, height: 44)
    }
}
