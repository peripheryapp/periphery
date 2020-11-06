import SwiftUI

struct ContentView: View {
    @State private var xibControllerPresented = false
    @State private var storyboardControllerPresented = false

    var body: some View {
        VStack {
            Button("XibViewController") {
                self.xibControllerPresented = true
            }.sheet(isPresented: $xibControllerPresented) {
                XibViewControllerWrapper()
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
