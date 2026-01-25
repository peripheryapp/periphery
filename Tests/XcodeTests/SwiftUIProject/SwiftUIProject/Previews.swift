import SwiftUI

struct PreviewOnlyView: View {
    var body: some View {
        Text("Hello, world!")
    }
}

struct PreviewOnlyView_PreviewProvider: PreviewProvider {
    static var previews: some View {
        PreviewOnlyView()
    }
}

#Preview {
    PreviewOnlyView()
}
