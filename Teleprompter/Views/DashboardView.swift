//  Teleprompter
//
//  Created by abaig on 17/01/2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct DashboardView: View {
    @State private var selectedContent: ContentItem? = nil
    @State private var isSettingsVisible = false
    @State private var showShareSheet = false
    @State private var masterViewVisibility: NavigationSplitViewVisibility = .all
    @State private var isDetailActive = false
    @State private var isImportingText = false
    

    var body: some View {
        if UIDevice.current.isPad {
            // iPad & Mac Catalyst: Split View
            NavigationSplitView(columnVisibility: $masterViewVisibility) {
                ContentListView(selectedContent: $selectedContent, isDetailActive: $isDetailActive)
                    .frame(minWidth: 300)
                    .onChange(of: masterViewVisibility) { _, newValue in
                        if newValue == .detailOnly {
                            CommonFunctions.endAnyTextFieldEditing()
                        }
                    }
            } detail: {
                detailViewSection
            }
            .accentColor(.white)
            .navigationSplitViewStyle(.automatic)
            .onChange(of: selectedContent) { _, newValue in
                // Automatically hide sidebar when an item is selected (show detail fullscreen)
                withAnimation {
                    masterViewVisibility = newValue == nil ? .all : .detailOnly
                    isDetailActive = newValue == nil ? false: true
                }
            }
        } else {
            // iPhone: NavigationStack
                ContentListView(
                    selectedContent: $selectedContent,
                    isDetailActive: $isDetailActive
                ).navigationDestination(isPresented: $isDetailActive) {
                    detailViewSection.navigationBarBackButtonHidden(true)
                        .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: {
                                // Clear selected content and show master
                                withAnimation {
                                    masterViewVisibility = .all
                                    isDetailActive = false
                                }
                            }) {
                                Label("", systemImage: "sidebar.leading")
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    }.onChange(of: selectedContent) { _, newValue in
                        // Automatically hide sidebar when an item is selected (show detail fullscreen)
                        withAnimation {
                            isDetailActive = true
                            masterViewVisibility = .detailOnly
                        }
                    }
//            .accentColor(.white)
        }
    }
    private var detailViewSection: some View {
        
        HStack(spacing: 0) {
            detailView.fileImporter(                                // ← NEW
                isPresented: $isImportingText,
                allowedContentTypes: [
                        .plainText,
                        .utf8PlainText,
                        .text,
                        //UTType(importedAs: "net.daringfireball.markdown") // ← replaces .markdown
                    ],
                allowsMultipleSelection: false
            ) { result in
                do {
                    guard let url = try result.get().first else { return }
                    
                    // Start accessing security-scoped resource
                    guard url.startAccessingSecurityScopedResource() else {
                        print("Permission denied for: \(url)")
                        return
                    }

                    defer { url.stopAccessingSecurityScopedResource() }

                    let text = try String(contentsOf: url, encoding: .utf8)
                    selectedContent?.text = (selectedContent?.text ?? "") + text
                } catch {
                    print("Import failed: \(error.localizedDescription)")
                }
            }
                
            settingsViewSection
        }
    }
    
    private var detailView: some View {
        Group {
            if let content = selectedContent {
                DetailView(selectedContent: Binding(
                    get: { content },
                    set: { selectedContent = $0 }
                ), masterViewVisibility: $masterViewVisibility)
            } else {
                Text("Select a content item to begin.")
                    .font(.title)
                    .padding()
            }
        }
        .padding(.top)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                navBarButtons
            }
        }
        .navigationTitle("Teleprompter")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShareSheet) {
            if let content = selectedContent {
                ShareSheet(activityItems: ["\(content.title)\n\n\(content.text)"])
            }
        }
    }

    private var settingsViewSection: some View {
        Group {
            if let content = selectedContent, isSettingsVisible {
                SettingsView(selectedContent: Binding(
                    get: { content },
                    set: { selectedContent = $0 }
                ))
                .frame(width: 300)
                .transition(.move(edge: .trailing))
                .animation(.easeInOut, value: isSettingsVisible)
            }
        }
    }

    private var navBarButtons: some View {
        HStack(spacing: 16) {
            Menu {
                Button(action: { isImportingText = true }){
                    Label("Import Text", systemImage: "tray.and.arrow.down")
                }
                
                Button(action: { showShareSheet = true }){
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundColor(.white)
            }
            Button {
                withAnimation { isSettingsVisible.toggle() }
            } label: {
                Image(systemName: isSettingsVisible ? "xmark" : "gear")
                    .foregroundColor(.white)
            }
        }
    }
}
