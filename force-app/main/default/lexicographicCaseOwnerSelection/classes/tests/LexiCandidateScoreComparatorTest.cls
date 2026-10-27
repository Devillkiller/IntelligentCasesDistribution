@isTest
private class LexiCandidateScoreComparatorTest {

    @isTest
    static void testGetInstance() {
        Assert.isNull(
            LexicographicCandidateScoreComparator.instance,
            'No instance should be created untill .getInstance() method is executed.'
        );

        LexicographicCandidateScoreComparator comparator =
            LexicographicCandidateScoreComparator.getInstance();

        Assert.isNotNull(
            LexicographicCandidateScoreComparator.instance,
            'Instance should be created after .getInstance() method is executed.'
        );
        Assert.areEqual(
            comparator,
            LexicographicCandidateScoreComparator.instance,
            'Returned instance should be the same as static one.'
        );
    }

    @isTest
    static void testCompare_moreMatchedSkillsWins() {
        LexicographicCandidateScore first
            = new LexicographicCandidateScore(null, 3, 2.0);

        LexicographicCandidateScore second 
            = new LexicographicCandidateScore(null, 2, 5.0);

        Integer result =
            LexicographicCandidateScoreComparator.getInstance().compare(
                first,
                second
            );

        Assert.areEqual(
            1,
            result,
            'Candidate with more matched skills should have higher priority '
                + 'regardless of average mastery.'
        );
    }

    @isTest
    static void testCompare_fewerMatchedSkillsLoses() {
        LexicographicCandidateScore first =
            new LexicographicCandidateScore(null, 2, 5.0);

        LexicographicCandidateScore second =
            new LexicographicCandidateScore(null, 3, 2.0);

        Integer result =
            LexicographicCandidateScoreComparator.getInstance().compare(
                first,
                second
            );

        Assert.areEqual(
            -1,
            result,
            'Candidate with fewer matched skills should have lower priority regardless '
                + 'of average mastery.'
        );
    }

    @isTest
    static void testCompare_higherAverageMasteryWins() {
        LexicographicCandidateScore first =
            new LexicographicCandidateScore(null, 3, 4.0);

        LexicographicCandidateScore second =
            new LexicographicCandidateScore(null, 3, 3.0);

        Integer result =
            LexicographicCandidateScoreComparator.getInstance().compare(
                first,
                second
            );

        Assert.areEqual(
            1,
            result,
            'Higher average mastery should have priority when matched skills '
                + 'count is equal.'
        );
    }

    @isTest
    static void testCompare_lowerAverageMasteryLoses() {
        LexicographicCandidateScore first =
            new LexicographicCandidateScore(null, 3, 3.0);

        LexicographicCandidateScore second =
            new LexicographicCandidateScore(null, 3, 4.0);

        Integer result =
            LexicographicCandidateScoreComparator.getInstance().compare(
                first,
                second
            );

        Assert.areEqual(
            -1,
            result,
            'Lower average mastery should have lower priority when matched skills '
                + 'count is equal.'
        );
    }

    @isTest
    static void testCompare_equalScores() {
        LexicographicCandidateScore first =
            new LexicographicCandidateScore(null, 3, 4.0);

        LexicographicCandidateScore second =
            new LexicographicCandidateScore(null, 3, 4.0);

        Integer result =
            LexicographicCandidateScoreComparator.getInstance().compare(
                first,
                second
            );

        Assert.areEqual(
            0,
            result,
            'Equivalent candidate scores should return zero.'
        );
    }
}