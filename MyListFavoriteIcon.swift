//
//  MyListFavoriteIcon.swift
//  Swedishly
//

import SwiftUI

struct MyListFavoriteIcon: View {
    let isInList: Bool

    var body: some View {
        Image("My list")
            .resizable()
            .renderingMode(.template)
            .aspectRatio(contentMode: .fit)
            .frame(width: 24, height: 24)
            .foregroundColor(isInList ? .green : .gray)
    }
}
