//
//  DetailView.swift
//  Teleprompter
//
//  Created by abaig on 18/12/2024.
//

import SwiftUI

struct SettingsView: View {
    
    @Binding var selectedContent: ContentItem
    @State private var showFontPicker: Bool = false
    
    var body: some View {
        
        Form {
            Section(header: Text("Settings")) {
                Toggle(
                    "Mirror",
                    isOn: $selectedContent.settings.isMirrorEnabled
                )
                .onChange(
                    of: selectedContent.settings.isMirrorEnabled
                ) { _, _ in
                    try? selectedContent.modelContext?.save()
                }
                ColorPicker(
                    "Background Color",
                    selection: $selectedContent.settings.backgroundColor
                )
                .onChange(
                    of: selectedContent.settings.backgroundColor
                ) { _, _ in
                    try? selectedContent.modelContext?.save()
                }
                .padding(.vertical, 5)
                ColorPicker(
                    "Text Color",
                    selection: $selectedContent.settings.textColor
                )
                .onChange(of: selectedContent.settings.textColor) { _, _ in
                    try? selectedContent.modelContext?.save()
                }
                .padding(.vertical, 5)
                HStack {
                    Text("Choose Font")
                    Spacer()
                    Button(selectedContent.settings.fontName) {
                        showFontPicker.toggle()
                    }.foregroundColor(.white)
                        .sheet(isPresented: $showFontPicker) {
                            FontPickerView(
                                fontName: $selectedContent.settings.fontName,
                                fontSize: $selectedContent.settings.fontSize
                            )
                            .onChange(
                                of: selectedContent.settings.fontName
                            ) { _, _ in
                                try? selectedContent.modelContext?.save()
                            }
                        }
                }
                
                HStack {
                    Text("Font Size")
                        .frame(minWidth: 80)
                        .accessibilityLabel("Current font size")
                    Spacer()
                    // Decrease font size button
                    Button(
                        action: {
                            if let currentIndex = SettingsConstants.fontSizes.firstIndex(
                                where: { $0 == selectedContent.settings.fontSize
                                }) {
                                if (currentIndex > 0) {
                                    selectedContent.settings.fontSize = SettingsConstants
                                        .fontSizes[currentIndex - 1]
                                }
                            }else {
                                selectedContent.settings.fontSize = SettingsConstants.fontSizes.first!
                            }
                            try? selectedContent.modelContext?.save()
                        }) {
                            Image(systemName: "minus.circle")
                                .font(.title).foregroundColor(.white)
                        }
                        .accessibilityLabel("Decrease font size")
                        .buttonStyle(.borderless)
                    
                    Text("\(Int(selectedContent.settings.fontSize)) pt")
                        .frame(minWidth: 80)
                    
                    // Increase font size button
                    Button(
                        action: {
                            if let currentIndex = SettingsConstants.fontSizes.firstIndex(
                                where: { $0 == selectedContent.settings.fontSize
                                }) {
                                if (
                                    currentIndex < SettingsConstants.fontSizes.count - 1
                                ) {
                                    selectedContent.settings.fontSize = SettingsConstants
                                        .fontSizes[currentIndex + 1]
                                }
                            } else {
                                selectedContent.settings.fontSize = SettingsConstants.fontSizes.last!
                            }
                            try? selectedContent.modelContext?.save()
                        }) {
                            Image(systemName: "plus.circle")
                                .font(.title).foregroundColor(.white)
                        }
                        .accessibilityLabel("Increase font size")
                        .buttonStyle(.borderless)
                }
                
                HStack {
                    Text("Text Alignment")
                    Spacer()
                    // Text Justification Picker
                    Picker(
                        "",
                        selection: $selectedContent.settings.textAlignment
                    ) {
                        Image(systemName: "text.alignleft")
                            .tag(TextAlignment.leading).foregroundColor(.white)
                        Image(systemName: "text.aligncenter")
                            .tag(TextAlignment.center).foregroundColor(.white)
                        Image(systemName: "text.alignright")
                            .tag(TextAlignment.trailing).foregroundColor(.white)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(
                        of: selectedContent.settings.textAlignment
                    ) { _, _ in
                        try? selectedContent.modelContext?.save()
                    }
                }
                HStack{
                    Text("Font Weight")
                    Spacer()
                    Picker(
                        "",
                        selection: $selectedContent.settings.selectedFontWeight
                    ) {
                        ForEach(TextFontWeight.allCases) { textFontWeight in
                            Text(textFontWeight.rawValue).tag(textFontWeight)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(
                        of: selectedContent.settings.selectedFontWeight
                    ) { _, _ in
                        try? selectedContent.modelContext?.save()
                    }
                }
                
                .padding(.vertical, 5)
                
                
                Picker(
                    "Countdown",
                    selection: $selectedContent.settings.selectedCountdown
                ) {
                    ForEach(
                        SettingsConstants.countdownPickerValues,
                        id: \.self
                    ) { countdown in
                        Text("\(countdown) sec").tag(countdown)
                    }
                }
                .pickerStyle(
                    MenuPickerStyle()
                ) // Use a menu-style picker for compactness
                .onChange(
                    of: selectedContent.settings.selectedCountdown
                ) { _, _ in
                    try? selectedContent.modelContext?.save()
                }
                
                HStack{
                    Text("Mode")
                    Spacer()
                    Picker(
                        "",
                        selection: $selectedContent.settings.selectedMode
                    ) {
                        ForEach(Mode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(
                        of: selectedContent.settings.selectedMode
                    ) { _, _ in
                        try? selectedContent.modelContext?.save()
                    }
                }
                
                .padding(.vertical, 5)
                
                if selectedContent.settings.selectedMode == .automatic {
                    Picker(
                        "Speed",
                        selection: $selectedContent.settings.selectedSpeed
                    ) {
                        ForEach(
                            SettingsConstants.speedPickerValues,
                            id: \.self
                        ) { speed in
                            Text(String(format: "%.1f", speed))
                                .tag(speed)
                        }
                    }
                    .pickerStyle(
                        MenuPickerStyle()
                    )
                    .onChange(
                        of: selectedContent.settings.selectedSpeed
                    ) { _, _ in
                        try? selectedContent.modelContext?.save()
                    }
                }
                
                if selectedContent.settings.selectedMode == .automatic {
                    Toggle("Show Timer", isOn: $selectedContent.settings.showTimer)
                        .onChange(of: selectedContent.settings.showTimer) { _, _ in
                            try? selectedContent.modelContext?.save()
                        }
                }
                
                VStack {
                    HStack {Text("Top: ")
                        Spacer()
                        Text("\(String(format: "%.1f", selectedContent.settings.topPadding))")}
                    Slider(value: $selectedContent.settings.topPadding, in: SettingsConstants.topAndBottomPaddingRange, step: 0.1)
                        .padding(.vertical, 5)
                }

                VStack {
                    HStack {Text("Bottom: ")
                        Spacer()
                        Text("\(String(format: "%.1f", selectedContent.settings.bottomPadding))")}
                    Slider(value: $selectedContent.settings.bottomPadding, in: SettingsConstants.topAndBottomPaddingRange, step: 0.1)
                        .padding(.vertical, 5)
                }
                
                VStack {
                    HStack {Text("Leading: ")
                        Spacer()
                        Text("\(String(format: "%.1f", selectedContent.settings.leadingPadding))")}
                    Slider(value: $selectedContent.settings.leadingPadding, in: SettingsConstants.leadingAndTrailingPaddingRange, step: 0.1)
                        .padding(.vertical, 5)
                }
                
                VStack {
                    HStack {Text("Trailing: ")
                        Spacer()
                        Text("\(String(format: "%.1f", selectedContent.settings.trailingPadding))")}
                    Slider(value: $selectedContent.settings.trailingPadding, in: SettingsConstants.leadingAndTrailingPaddingRange, step: 0.1)
                        .padding(.vertical, 5)
                }
            }
        }
    }
}
