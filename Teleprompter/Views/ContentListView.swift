import Foundation
import SwiftUI
import SwiftData

struct ContentListView: View {
    @Query(sort: \ContentItem.order) private var contents: [ContentItem]
    @Binding var selectedContent: ContentItem?
    @Environment(\.modelContext) private var modelContext
    @Binding var isDetailActive: Bool

    @State private var isEditingContentList = false

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        VStack {
            headerView
            contentListView
            addButton
        }
        .onAppear {
            loadLastSelectedContent()
            if contents.isEmpty {
                createContent()
            }
        }
    }

    func loadLastSelectedContent() {
        if let savedID = UserDefaults.standard.string(forKey: "lastSelectedContentID"),
           let matchedContent = contents.first(where: { $0.id.uuidString == savedID }) {
            selectedContent = matchedContent
        }
    }

    private var headerView: some View {
        HStack {
            Text("Content List").font(.headline)
            Spacer()
            Button(isEditingContentList ? "Done" : "Edit") {
                isEditingContentList.toggle()
            }
            .font(.headline)
            .foregroundColor(.white)
        }
        .padding()
    }

    private var contentListView: some View {
        List {
            ForEach(contents) { content in
                Button(action: { selectContent(content) }) {
                    contentRow(for: content)
                }
            }
            .onDelete(perform: isEditingContentList ? deleteContent : nil)
            .onMove(perform: isEditingContentList ? moveContent : nil)
        }
        #if os(iOS)
        .environment(\.editMode, .constant(isEditingContentList ? .active : .inactive))
        #endif
    }

    private var addButton: some View {
        Button(
            action: {
                if let existingEmptyContent = contents.first(where: { $0.title.isEmpty && $0.text.isEmpty }) {
                    selectContent(existingEmptyContent)
                } else {
                    createContent()
                }
            }
        ) {
            Image(systemName: "plus.circle")
                .resizable()
                .frame(width: 30, height: 30)
                .foregroundColor(.white)
                .padding()
        }
    }

    private func contentRow(for content: ContentItem) -> some View {
        HStack() {
            VStack(alignment: .leading) {
                Text(content.title)
                    .font(.headline)
                    .foregroundColor(selectedContent?.id == content.id ? .white : .gray)
                HStack {
                    Text("Created at: \(content.createdAt, formatter: dateFormatter)")
                        .font(.footnote)
                        .foregroundColor(.gray)
                    Spacer()
                    Text("Last Updated at: \(content.updatedAt, formatter: dateFormatter)")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
            }
            Spacer()

                    if selectedContent?.id == content.id {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.white)
                            .imageScale(.small)
                    }
        }
        .padding()
        .background(selectedContent?.id == content.id ? Color.blue.opacity(0.2) : Color.clear)
        .cornerRadius(8)
    }

    func deleteContent(at offsets: IndexSet) {
        for index in offsets {
            let content = contents[index]
            modelContext.delete(content)
            if selectedContent?.id == content.id {
                selectedContent = nil
                UserDefaults.standard.removeObject(forKey: "lastSelectedContentID")
            }
        }
        updateContentOrder()
    }

    func selectContent(_ content: ContentItem) {
        selectedContent = content
        isDetailActive = true
        UserDefaults.standard.set(content.id.uuidString, forKey: "lastSelectedContentID")
    }

    func moveContent(from source: IndexSet, to destination: Int) {
        var updatedContents = contents
        updatedContents.move(fromOffsets: source, toOffset: destination)
        for (index, content) in updatedContents.enumerated() {
            content.order = index
        }
        try? modelContext.save()
    }

    func createContent() {
        let newContent = ContentItem(title: "", text: "", order: contents.count)
        modelContext.insert(newContent)
        selectContent(newContent)
        try? modelContext.save()
        updateContentOrder()
    }

    func updateContentOrder() {
        for (index, content) in contents.enumerated() {
            content.order = index
        }
        try? modelContext.save()
    }
}
