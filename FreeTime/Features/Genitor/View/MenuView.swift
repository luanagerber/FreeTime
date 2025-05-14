//
//  MenuView.swift
//  FreeTime
//
//  Created by Thales Araújo on 14/05/25.
//

import SwiftUI

struct MenuView: View {
    @State private var selectedOption = "Opção 1"
    let options = ["Opção 1", "Opção 2", "Opção 3"]

    var body: some View {
        Picker("Escolha uma opção", selection: $selectedOption) {
            ForEach(options, id: \.self) { option in
                Text(option)
            }
        }
        .pickerStyle(MenuPickerStyle())  // aqui define o estilo menu (pull-down)
        .padding()
    }
}

#Preview {
    MenuView()
}
