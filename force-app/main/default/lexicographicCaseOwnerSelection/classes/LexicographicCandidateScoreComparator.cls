public with sharing class LexicographicCandidateScoreComparator {

    @TestVisible
    private static LexicographicCandidateScoreComparator instance;

    public static LexicographicCandidateScoreComparator getInstance() {
        if (null == instance) {
            instance = new LexicographicCandidateScoreComparator();
        }
        return instance;
    }

    public Integer compare(
        LexicographicCandidateScore first,
        LexicographicCandidateScore second
    ) {
        if (first.matchedSkillsCount > second.matchedSkillsCount) {
            return 1;
        }

        if (first.matchedSkillsCount < second.matchedSkillsCount) {
            return -1;
        }

        if (first.averageMastery > second.averageMastery) {
            return 1;
        }

        if (first.averageMastery < second.averageMastery) {
            return -1;
        }

        return 0;
    }
}