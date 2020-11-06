import Foundation
import SwiftUI

struct PreviewProviderRetainedView: View {
    var body: some View {
        Text("Hello, world!").padding()
    }
}

struct PreviewProviderRetainedViewPreview: PreviewProvider {
    static var previews: some View {
        PreviewProviderRetainedView()
    }
}
