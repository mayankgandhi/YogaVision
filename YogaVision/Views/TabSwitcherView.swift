//
//  TabSwitcherView.swift
//  YogaVision
//
//  Created by Mayank Gandhi on 3/14/21.
//

import Foundation
import SwiftUI

struct AnchorKey: PreferenceKey {
  static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
    value = value ?? nextValue()
  }
}


struct TabBar<T: View>: View {
  var items: [T]
  @State var selectedIndex: Int = 0

  private func item(at index: Int) -> some View {
    Button(action: {
      withAnimation(.default) {
        self.selectedIndex = index
      }
    }) {
      VStack {
        items[index]
      }
    }
    .anchorPreference(key: AnchorKey.self, value: .bounds, transform: { self.selectedIndex == index ? $0 : nil})
    .accentColor(index == selectedIndex ? .blue : .primary)
  }

  private func indicator(_ bounds: Anchor<CGRect>?) -> some View {
    GeometryReader { proxy in
      if bounds != nil {
        Rectangle()
          .fill(Color.blue)
          .frame(width: proxy[bounds!].width, height: 1)
          .offset(x: proxy[bounds!].minX, y: 3)
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
      }
    }
  }

  var body: some View {
    HStack {
      ForEach(items.indices, id: \.self) {
        self.item(at: $0)
      }
    }.overlayPreferenceValue(AnchorKey.self, {
      self.indicator($0)
    })
  }
}
