import SwiftUI

struct ContentView: View {
    var body: some View {
        Text("Hello, world!")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct LibraryViewContent: LibraryContentProvider {
    var views: [LibraryItem] {
        LibraryItem(ContentView())
    }
}
