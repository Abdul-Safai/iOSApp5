import SwiftUI
import SwiftData
import MapKit

struct ContentView: View {
    @Query(sort: [SortDescriptor(\Note.createdAt, order: .reverse)]) private var notes: [Note]
    @Environment(\.modelContext) private var context

    // UI state
    @State private var showingAdd = false
    @State private var query = ""
    @State private var sortNewest = true
    @State private var showOnboarding = false
    @State private var toast: String?

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false

    private var filtered: [Note] {
        let base = notes.filter {
            query.isEmpty ||
            $0.title.localizedCaseInsensitiveContains(query) ||
            $0.detail.localizedCaseInsensitiveContains(query)
        }
        return sortNewest ? base : base.sorted { $0.createdAt < $1.createdAt }
    }

    var body: some View {
        ToastHost(message: $toast) {
            NavigationStack {
                ZStack {
                    Color(.systemBackground).ignoresSafeArea()

                    ScrollView {
                        VStack(spacing: 16) {
                            Header(title: "UniMedia Notes") { }

                            HStack(spacing: 10) {
                                SearchField(text: $query, placeholder: "Search notes…")
                                Picker("", selection: $sortNewest) {
                                    Text("Newest").tag(true)
                                    Text("Oldest").tag(false)
                                }
                                .pickerStyle(.segmented)
                                .frame(maxWidth: 160)
                            }
                            .padding(.horizontal)

                            if filtered.isEmpty {
                                EmptyState(
                                    title: query.isEmpty ? "No Notes Yet" : "No Results",
                                    message: query.isEmpty
                                        ? "Tap the + button to add your first media note."
                                        : "Try a different search or clear the query."
                                )
                                .padding(.top, 24)
                                .padding(.horizontal)
                            } else {
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: 14)], spacing: 14) {
                                    ForEach(filtered) { note in
                                        NavigationLink(value: note) {
                                            NoteCardModern(note: note)
                                        }
                                        .buttonStyle(.plain)
                                        .contextMenu {
                                            Button(role: .destructive) {
                                                note.attachments.forEach { MediaStore.delete(fileName: $0.fileName) }
                                                context.delete(note)
                                                try? context.save()
                                                toast = "Deleted “\(note.title)”"
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { toast = nil }
                                            } label: { Label("Delete", systemImage: "trash") }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 100) // space for FAB
                            }
                        }
                        .padding(.top, 8)
                    }

                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            FloatingAddButton { showingAdd = true }
                                .padding(.trailing, 18)
                                .padding(.bottom, 24)
                        }
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("UniMedia Notes")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                    }
                }
                .navigationDestination(for: Note.self) {
                    NoteDetailView(note: $0, onShare: { toast = "Shared!" })
                }
                .sheet(isPresented: $showingAdd) {
                    AddEditNoteView(onSaved: {
                        toast = "Saved!"
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { toast = nil }
                    })
                }
                .onAppear { showOnboarding = !hasSeenOnboarding }
                .sheet(isPresented: $showOnboarding) {
                    OnboardingView(isPresented: $showOnboarding, onFinished: {
                        hasSeenOnboarding = true
                    })
                }
            }
        }
    }
}

// MARK: - Header
private struct Header: View {
    var title: String
    var action: (() -> Void)? = nil

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppTheme.gradient)
                .frame(height: 120)
                .overlay(
                    ZStack {
                        Circle().strokeBorder(.white.opacity(0.15), lineWidth: 1)
                            .scaleEffect(0.9)
                            .offset(x: 120, y: -30)
                        Circle().strokeBorder(.white.opacity(0.12), lineWidth: 1)
                            .scaleEffect(1.2)
                            .offset(x: 160, y: 20)
                    }
                )
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text("Capture notes with photos, videos & location.")
                    .font(.callout)
                    .foregroundStyle(.primary.opacity(0.9))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
        }
        .shadow(color: .black.opacity(0.08), radius: 10, y: 6)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Search Field
private struct SearchField: View {
    @Binding var text: String
    var placeholder: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(AppTheme.cardBackground(.light), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.separator.opacity(0.3)))
    }
}

// MARK: - Note Card (modern + no-clip text + right inset)
private struct NoteCardModern: View {
    let note: Note
    private let textInset: CGFloat = 8  // ← adjust this (e.g., 6–12) to move text further right

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // HERO
            ZStack(alignment: .bottomLeading) {
                if let att = note.attachments.first,
                   let data = att.thumbData,
                   let img = UIImage(data: data) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 170)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay {
                            LinearGradient(
                                colors: [.black.opacity(0.0), .black.opacity(0.35)],
                                startPoint: .top, endPoint: .bottom
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                        }
                        .overlay(alignment: .bottomLeading) {
                            HStack(spacing: 8) {
                                if !note.attachments.isEmpty {
                                    Label("\(note.attachments.count)", systemImage: "paperclip")
                                        .font(.caption.weight(.semibold))
                                        .padding(.horizontal, 10).padding(.vertical, 6)
                                        .background(.ultraThinMaterial, in: Capsule())
                                }
                                if note.latitude != nil {
                                    Image(systemName: "mappin.and.ellipse")
                                        .font(.caption.weight(.semibold))
                                        .padding(.horizontal, 10).padding(.vertical, 6)
                                        .background(.ultraThinMaterial, in: Capsule())
                                }
                            }
                            .padding(10)
                        }
                } else {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(AppTheme.gradient.opacity(0.7))
                        .frame(height: 170)
                        .overlay(
                            Image(systemName: "photo.on.rectangle")
                                .font(.title)
                                .foregroundStyle(.secondary)
                        )
                }
            }

            // TEXT STACK (shifted to the right a bit)
            VStack(alignment: .leading, spacing: 8) {
                // TITLE — allow up to 3 lines; never clip
                Text(note.title)
                    .font(.headline)
                    .lineLimit(3)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .layoutPriority(2)
                    .padding(.top, 2)

                // SUBTITLE — allow up to 3 lines; never clip
                Text(note.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .layoutPriority(1)

                // META ROW
                HStack(spacing: 8) {
                    Image(systemName: "calendar"); Text(note.createdAt, style: .date)
                    Spacer(minLength: 8)
                    Image(systemName: "clock"); Text(note.createdAt, style: .time)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom, 2)
            }
            .padding(.leading, textInset)   // ← the right-shift for title/detail/meta
        }
        .padding(12)
        .glassCard()
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Note \(note.title)")
    }
}


// MARK: - Empty State
private struct EmptyState: View {
    var title: String
    var message: String
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "doc.text.image")
                .font(.system(size: 56, weight: .regular))
                .foregroundStyle(.secondary)
            Text(title).font(.title3.weight(.semibold))
            Text(message).multilineTextAlignment(.center).foregroundStyle(.secondary)
        }
        .padding(24)
        .background(
            AppTheme.cardBackground(.light),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .shadow(color: .black.opacity(0.08), radius: 10, y: 6)
    }
}

// MARK: - Floating Add Button
private struct FloatingAddButton: View {
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.title2.weight(.bold))
                .padding(18)
                .background(AppTheme.gradient)
                .clipShape(Circle())
                .shadow(radius: 10, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add Note")
    }
}
