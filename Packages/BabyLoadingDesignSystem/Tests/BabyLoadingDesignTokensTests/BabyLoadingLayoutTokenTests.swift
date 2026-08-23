import Testing
@testable import BabyLoadingDesignTokens

struct BabyLoadingLayoutTokenTests {
    @Test
    func spacingUsesFourPointScale() {
        #expect(BabyLoadingSpacing.extraSmall == 4)
        #expect(BabyLoadingSpacing.small == 8)
        #expect(BabyLoadingSpacing.medium == 16)
        #expect(BabyLoadingSpacing.large == 24)
        #expect(BabyLoadingSpacing.extraLarge == 32)
    }

    @Test
    func sharedCardShapesPreserveExistingRadii() {
        #expect(BabyLoadingShape.timelineCardCornerRadius == 16)
        #expect(BabyLoadingShape.softCardCornerRadius == 24)
    }

    @Test
    func elevationPreservesExistingShadowGeometry() {
        #expect(BabyLoadingElevation.softCard.radius == 12)
        #expect(BabyLoadingElevation.softCard.horizontalOffset == 0)
        #expect(BabyLoadingElevation.softCard.verticalOffset == 6)
        #expect(BabyLoadingElevation.selectedTimelineCard.radius == 8)
        #expect(BabyLoadingElevation.selectedTimelineCard.horizontalOffset == 0)
        #expect(BabyLoadingElevation.selectedTimelineCard.verticalOffset == 4)
    }
}
