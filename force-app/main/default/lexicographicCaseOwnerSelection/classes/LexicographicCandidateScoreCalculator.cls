public with sharing class LexicographicCandidateScoreCalculator {

    @TestVisible
    private static LexicographicCandidateScoreCalculator instance;

    public static LexicographicCandidateScoreCalculator getInstance() {
        if (null == instance) {
            instance = new LexicographicCandidateScoreCalculator();
        }
        return instance;
    }

    public LexicographicCandidateScore calculate(
        Id userId,
        Set<String> requiredSkills,
        List<UserSkill__c> userSkills
    ) {
        Set<String> matchedSkills = new Set<String>();
        Decimal totalMasterity = 0;
        if (null != userSkills) {
            for (UserSkill__c userSkill : userSkills) {
                if (
                    String.isBlank(userSkill.SkillName__c)
                    || !requiredSkills.contains(userSkill.SkillName__c)
                ) {
                    continue;
                }
                if (
                    String.isBlank(userSkill.Mastery__c)
                    || matchedSkills.contains(userSkill.SkillName__c)
                ) {
                    continue;
                }
                matchedSkills.add(userSkill.SkillName__c);
                totalMasterity += Integer.valueOf(userSkill.Mastery__c);
            }
        }

        Integer matchedSkillsCount = matchedSkills.size();
        Decimal averageMastery = 0;
        if (matchedSkillsCount > 0) {
            averageMastery = totalMasterity / matchedSkillsCount;
        }

        return new LexicographicCandidateScore(
            userId,
            matchedSkillsCount,
            averageMastery
        );
    }
}