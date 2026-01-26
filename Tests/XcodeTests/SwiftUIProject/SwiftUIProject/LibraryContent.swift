import SwiftUI

struct LibraryOnlyView: View {
  var body: some View {
    Text("Hello, world!")
  }
}

 struct LibraryOnlyView_LibraryContentProvider: LibraryContentProvider {
     var views: [LibraryItem] {
         LibraryItem(LibraryOnlyView())
     }
 }
