import SwiftUI

struct ContentView: View {
    @State private var xibControllerPresented = false
    @State private var xibController2SubclassPresented = false
    @State private var storyboardControllerPresented = false

    var body: some View {
        VStack {
            Button("XibViewController") {
                self.xibControllerPresented = true
            }.sheet(isPresented: $xibControllerPresented) {
                XibViewControllerWrapper()
            }

            Button("XibViewController2Subclass") {
                self.xibController2SubclassPresented = true
            }.sheet(isPresented: $xibController2SubclassPresented) {
                XibViewController2SubclassWrapper()
            }

            Button("StoryboardViewController") {
                self.storyboardControllerPresented = true
            }.sheet(isPresented: $storyboardControllerPresented) {
                StoryboardViewControllerWrapper()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

#if swift(>=5.3)
struct LibraryViewContent: LibraryContentProvider {
    var views: [LibraryItem] {
        LibraryItem(ContentView())
    }
}
#endif
