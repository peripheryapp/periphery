import Foundation
import SPMProjectKit

func main() {
    print(SPMProject().text)
    print(PublicCrossModuleReferenced.self)
}

main()
