//
//  DetailView.swift
//  Teleprompter
//
//  Created by abaig on 18/12/2024.
//

import SwiftUI

struct DetailView: View {
    @Binding var selectedContent: ContentItem

    @State private var showTeleprompterAlert = false
//    @State private var showGlassesNotWornAlert = false
    @State private var showTeleprompter = false
    @State private var loadGlassTeleprompter = false
    
    @Binding var masterViewVisibility: NavigationSplitViewVisibility
    
    var body: some View {
        VStack(alignment: .leading) {
            TextField("Title", text: Binding(
                get: { selectedContent.title},
                set: { newValue in
                    selectedContent.title = newValue
                    selectedContent.updatedAt = Date()
                    try? selectedContent.modelContext?.save()
                }
            ))
            .font(.title)
            .padding(.horizontal)
                    
            HStack {
                Text(
                    "Words: \(CommonFunctions.getWordCount(text: selectedContent.text))"
                )
                .font(.subheadline)
                .foregroundColor(.gray)
            }
            .padding(.horizontal)
            Divider()
                    
                    
                    
            TextEditor(text: Binding(
                get: { selectedContent.text},
                set: { newValue in
                    selectedContent.text = newValue
                    selectedContent.updatedAt = Date()
                    try? selectedContent.modelContext?.save()
                }
            )).simultaneousGesture(
                TapGesture().onEnded {
                    // Hide master view when TextEditor is tapped
                    masterViewVisibility = .detailOnly
                }
            )
            .padding(EdgeInsets(top: selectedContent.settings.topPadding,
                                leading: selectedContent.settings.leadingPadding,
                                bottom: selectedContent.settings.bottomPadding,
                                trailing: selectedContent.settings.trailingPadding)
            )
            .scrollContentBackground(.hidden)
            .foregroundColor(selectedContent.settings.textColor)
            .font(
                Font(
                    selectedContent.settings.selectedFont
                )
            )
            .fontWeight(selectedContent.settings.selectedFontWeight == .bold ? .bold : .regular)
            .multilineTextAlignment(
                selectedContent.settings.textAlignment
            )
            .scrollIndicators(.hidden)
            Spacer()
                    
            // Start Teleprompter Button
            Button(action: {
                CommonFunctions.endAnyTextFieldEditing()
                showTeleprompterAlert = true
            }) {
                Text("Start Teleprompter")
                    .foregroundColor(.white)
                            .padding()
                            .background(Color.black)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white, lineWidth: 2)
                            )
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }.background(selectedContent.settings.backgroundColor)
//                .alert(isPresented: $showTeleprompterAlert) {
//                    Alert(
//                        title: Text("Select Teleprompter Type"),
//                        message: Text("Please choose the teleprompter mode you want to use."),
//                        primaryButton: .default(Text("Glass")) {
//                            loadGlassTeleprompter = true
//                           showTeleprompter = true
//                        },
//                        secondaryButton: .cancel(Text("Fullscreen")) {
//                            loadGlassTeleprompter = false
//                            showTeleprompter = true
//                        }
//                    )
//                }
//            .alert(isPresented: $showGlassesNotWornAlert) {
//                Alert(
//                    title: Text("Glasses Not Worn"),
//                    message: Text("Please wear the glasses to start Teleprompter"),
//                    dismissButton: .default(Text("Ok")) { }
//                )
//            }
            .confirmationDialog(
                "Select Teleprompter Type",
                isPresented: $showTeleprompterAlert,
                titleVisibility: .visible
            ) {
                Button("Glasses") {
//                    if (BleManager.shared.connectedGlasses?.glassStatus != .glassesWorn) {
//                        showGlassesNotWornAlert = true
//                    }else {
                        loadGlassTeleprompter = true
                        showTeleprompter = true
//                    }
                }
                Button("Fullscreen") {
                    loadGlassTeleprompter = false
                    showTeleprompter = true
                }
                Button("Cancel", role: .cancel) { }
            }

                #if os(iOS)
                .fullScreenCover(isPresented: $showTeleprompter) {
                    
                    TeleprompterView(
                        onClose: { showTeleprompter = false },
                        loadGlassView: loadGlassTeleprompter, selectedContent: $selectedContent
                    )
                    .disableIdleTimer()
                }
                #else
                .sheet(isPresented: $showTeleprompter) {
                    TeleprompterView(
                        onClose: { showTeleprompter = false },
                        selectedContent: $selectedContent
                    )
                    .frame(minWidth: 800, minHeight: 600) // Adjust size for macOS
                }
                #endif
    }
}
