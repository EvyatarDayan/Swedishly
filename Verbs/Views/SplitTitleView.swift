//
//  SplitTitleView.swift
//  SWVerbs
//
//  Created by EVYATAR DAYAN on 2026-01-17.
//

import SwiftUI

struct SplitTitleView: View {
    let title: String
    let splitIndex: Int
    
    init(_ title: String, splitIndex: Int? = nil) {
        self.title = title
        // If splitIndex not provided, split roughly in half
        if let splitIndex = splitIndex {
            self.splitIndex = splitIndex
        } else {
            self.splitIndex = title.count / 2
        }
    }
    
    private var firstPart: String {
        String(title.prefix(splitIndex))
    }
    
    private var secondPart: String {
        String(title.suffix(title.count - splitIndex))
    }
    
    var body: some View {
        HStack(spacing: 0) {
            Text(firstPart)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.blue)
            Text(secondPart)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.green)
        }
    }
}
