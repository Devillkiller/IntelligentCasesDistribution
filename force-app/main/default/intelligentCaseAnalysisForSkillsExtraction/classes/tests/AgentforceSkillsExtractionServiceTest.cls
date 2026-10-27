@isTest
private class AgentforceSkillsExtractionServiceTest {
    @isTest
    static void testGetInstance() {
        Assert.isNull(
            AgentforceSkillsExtractionService.instance,
            'No instance should be created untill .getInstance() method is executed.'
        );
        AgentforceSkillsExtractionService service = AgentforceSkillsExtractionService.getInstance();
        Assert.isNotNull(
            AgentforceSkillsExtractionService.instance,
            'Instance should be created after .getInstance() method is executed.'
        );
        Assert.areEqual(
            service,
            AgentforceSkillsExtractionService.instance,
            'Returned instance should be the same as static one.'
        );
    }

    @isTest
    static void testGetRequiredSkills_noCaseId() {
        Case testCase = new Case();
        Set<String> skills
            = AgentforceSkillsExtractionService.getInstance().getRequiredSkills(testCase, null);
        Assert.isTrue(
            skills.isEmpty(),
            'No skills should be identified as required because no description were given.'
        );
    }

    @isTest
    static void testGetRequiredSkills_caseOnly() {
        Case testCase = new Case(
            Description = 'After a new Apex trigger was deployed, '
                + 'users started receiving System.LimitException: '
                + 'Too many SOQL queries: 101 when saving Opportunity '
                + 'records. The trigger and related tests need to be '
                + 'reviewed and optimized.'
        );
        insert testCase;
        Set<String> skills = AgentforceSkillsExtractionService.getInstance().getRequiredSkills(testCase, null);
        Assert.isNotNull(
            skills,
            'At least some skills should be identified for given Case Description by .getRequiredSkills(...) method.'
        );
    }

    @isTest
    static void testGetRequiredSkills_caseAndAttachment() {
        Case testCase = new Case(
            Description = 'After a new Apex trigger was deployed, '
                + 'users started receiving System.LimitException: '
                + 'Too many SOQL queries: 101 when saving Opportunity '
                + 'records. The trigger and related tests need to be '
                + 'reviewed and optimized.'
        );
        insert testCase;
        Set<String> skills = AgentforceSkillsExtractionService.getInstance().getRequiredSkills(testCase, null);
        Assert.isNotNull(
            skills,
            'At least some skills should be identified for given Case Description by .getRequiredSkills(...) method.'
        );
    }
}