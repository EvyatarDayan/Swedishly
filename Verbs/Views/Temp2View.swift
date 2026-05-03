//
//  Temp2View.swift
//  SWVerbs
//
//  Created by EVYATAR DAYAN on 2026-01-05.
//

import SwiftUI

struct Temp2View: View {
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                Image(systemName: "2.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                Text("Temp2")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top)
                Text("Temporary view 2")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
                Spacer()
            }
            .navigationTitle("Temp2")
        }
        .navigationViewStyle(.stack)
    }
}

#Preview {
    Temp2View()
}


