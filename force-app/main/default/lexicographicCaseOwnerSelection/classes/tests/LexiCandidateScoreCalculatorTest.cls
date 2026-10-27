@isTest
private class LexiCandidateScoreCalculatorTest {

    private static final Id TEST_USER_ID = '005000000000001';

    @isTest
    static void testGetInstance() {
        Assert.isNull(
            LexicographicCandidateScoreCalculator.instance,
            'No instance should be created untill .getInstance() method is executed.'
        );

        LexicographicCandidateScoreCalculator calculator =
            LexicographicCandidateScoreCalculator.getInstance();

        Assert.isNotNull(
            LexicographicCandidateScoreCalculator.instance,
            'Instance should be created after .getInstance() method is executed.'
        );
        Assert.areEqual(
            calculator,
            LexicographicCandidateScoreCalculator.instance,
            'Returned instance should be the same as static one.'
        );
    }

    @isTest
    static void testCalculate_multipleRelevantSkills() {
        Set<String> requiredSkills = new Set<String>{
            'Apex Programming',
            'Debugging & Logs',
            'Flow Automation'
        };

        List<UserSkill__c> userSkills = new List<UserSkill__c>{
            new UserSkill__c(
                UserId__c = TEST_USER_ID,
                SkillName__c = 'Apex Programming',
                Mastery__c = '4'
            ),
            new UserSkill__c(
                UserId__c = TEST_USER_ID,
                SkillName__c = 'Debugging & Logs',
                Mastery__c = '3'
            ),
            new UserSkill__c(
                UserId__c = TEST_USER_ID,
                SkillName__c = 'Data Management',
                Mastery__c = '5'
            )
        };

        LexicographicCandidateScore score =
            LexicographicCandidateScoreCalculator.getInstance().calculate(
                TEST_USER_ID,
                requiredSkills,
                userSkills
            );

        Assert.areEqual(
            TEST_USER_ID,
            score.userId,
            'Score should be calculated for the provided User.'
        );
        Assert.areEqual(
            2,
            score.matchedSkillsCount,
            'Only skills relevant to the task should be counted.'
        );
        Assert.areEqual(
            3.5,
            score.averageMastery,
            'Average mastery should be calculated only for relevant skills.'
        );
    }

    @isTest
    static void testCalculate_noRelevantSkills() {
        Set<String> requiredSkills = new Set<String>{
            'Flow Automation'
        };

        List<UserSkill__c> userSkills = new List<UserSkill__c>{
            new UserSkill__c(
                UserId__c = TEST_USER_ID,
                SkillName__c = 'Apex Programming',
                Mastery__c = '5'
            ),
            new UserSkill__c(
                UserId__c = TEST_USER_ID,
                SkillName__c = 'Debugging & Logs',
                Mastery__c = '5'
            )
        };

        LexicographicCandidateScore score =
            LexicographicCandidateScoreCalculator.getInstance().calculate(
                TEST_USER_ID,
                requiredSkills,
                userSkills
            );

        Assert.areEqual(
            0,
            score.matchedSkillsCount,
            'No skills should be matched.'
        );
        Assert.areEqual(
            0.0,
            score.averageMastery,
            'Average mastery should be zero when there are no matched skills.'
        );
    }

    @isTest
    static void testCalculate_noUserSkills() {
        Set<String> requiredSkills = new Set<String>{
            'Apex Programming'
        };

        LexicographicCandidateScore score =
            LexicographicCandidateScoreCalculator.getInstance().calculate(
                TEST_USER_ID,
                requiredSkills,
                null
            );

        Assert.areEqual(
            0,
            score.matchedSkillsCount,
            'Matched skills count should be zero when User has no skills.'
        );
        Assert.areEqual(
            Decimal.valueOf('0'),
            score.averageMastery,
            'Average mastery should be zero when User has no skills.'
        );
    }

    @isTest
    static void testCalculate_emptyRequiredSkills() {
        LexicographicCandidateScore score =
            LexicographicCandidateScoreCalculator.getInstance().calculate(
                TEST_USER_ID,
                new Set<String>(),
                new List<UserSkill__c>{
                    new UserSkill__c(
                        UserId__c = TEST_USER_ID,
                        SkillName__c = 'Apex Programming',
                        Mastery__c = '5'
                    )
                }
            );

        Assert.areEqual(
            0,
            score.matchedSkillsCount,
            'No skills should be matched when required skills are empty.'
        );
        Assert.areEqual(
            Decimal.valueOf('0'),
            score.averageMastery,
            'Average mastery should be zero when required skills are empty.'
        );
    }
}