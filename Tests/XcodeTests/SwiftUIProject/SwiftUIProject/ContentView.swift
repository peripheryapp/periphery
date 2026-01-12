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

// View referenced only from #Preview (mirrors ContentView referenced from PreviewProvider)
struct DetailView: View {
    var body: some View {
        Text("Detail View")
    }
}

// Nested type referenced only from #Preview - tests nested type handling
struct PreviewHelpers {
    struct NestedHelper {
        static func makeText() -> String {
            "Nested Helper Text"
        }
    }
}

#Preview {
    DetailView()
    Text(PreviewHelpers.NestedHelper.makeText())
}
