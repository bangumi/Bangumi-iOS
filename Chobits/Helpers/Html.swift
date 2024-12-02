//
//  Html.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/12/1.
//

import SwiftUI

struct TestHTMLText: View {
  var body: some View {
    let html = "<h1>Heading</h1> <p>paragraph.</p>"

    if let nsAttributedString = try? NSAttributedString(
      data: Data(html.utf8), options: [.documentType: NSAttributedString.DocumentType.html],
      documentAttributes: nil),
      let attributedString = try? AttributedString(nsAttributedString, including: \.uiKit)
    {
      Text(attributedString)
    } else {
      // fallback...
      Text(html)
    }
  }
}

#Preview {
  TestHTMLText()
}
