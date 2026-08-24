import SwiftUI
import Testing
@testable import BabyLoadingDesignComponents

@MainActor
struct BabyLoadingDesignComponentsTests {
    @Test
    func gradientBackgroundRendersAtTheRequestedSize() {
        let renderer = ImageRenderer(
            content: GradientBackground()
                .frame(width: 120, height: 160)
        )
        renderer.proposedSize = ProposedViewSize(width: 120, height: 160)

        #expect(renderer.cgImage?.width == 120)
        #expect(renderer.cgImage?.height == 160)
    }

    @Test
    func softCardModifierRendersAtTheRequestedSize() {
        let renderer = ImageRenderer(
            content: Text("BabyLoading")
                .softCard()
                .frame(width: 200, height: 100)
        )
        renderer.proposedSize = ProposedViewSize(width: 200, height: 100)

        #expect(renderer.cgImage?.width == 200)
        #expect(renderer.cgImage?.height == 100)
    }
}
