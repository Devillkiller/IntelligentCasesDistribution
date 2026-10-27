@isTest
private class LexicographicCandidateScoreTest {

    @isTest
    static void testConstructor() {
        Id userId = '005000000000001';

        LexicographicCandidateScore score =
            new LexicographicCandidateScore(userId, 3, Decimal.valueOf('3.5'));

        Assert.areEqual(
            userId,
            score.userId,
            'User Id should be stored in the candidate score.'
        );
        Assert.areEqual(
            3,
            score.matchedSkillsCount,
            'Matched skills count should be stored in the candidate score.'
        );
        Assert.areEqual(
            3.5,
            score.averageMastery,
            'Average mastery should be stored in the candidate score.'
        );
    }
}