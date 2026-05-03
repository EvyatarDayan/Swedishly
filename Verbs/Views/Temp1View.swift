//
//  Temp1View.swift
//  SWVerbs
//
//  Created by EVYATAR DAYAN on 2026-01-05.
//

import SwiftUI

struct Temp1View: View {
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                Image(systemName: "1.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                Text("Temp1")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top)
                Text("Temporary view 1")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
                Spacer()
            }
            .navigationTitle("Temp1")
        }
        .navigationViewStyle(.stack)
    }
}

#Preview {
    Temp1View()
}


