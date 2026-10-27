@isTest
private class CaseAssignmentQueueableTest {

    private static final String ASSIGNEE_LAST_NAME = 'COMMON_QUEUEABLE_USER';

    @TestSetup
    static void setupData() {
        UserRole customerSupportRole = new UserRole(
            Name = 'Unit Test Customer Support Queueable'
        );

        insert customerSupportRole;

        String uniqueValue = ASSIGNEE_LAST_NAME + '.' + DateTime.now().getTime();

        User assignee = new User(
            Alias = 'cmnque',
            Email = uniqueValue + '@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = ASSIGNEE_LAST_NAME,
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = UserInfo.getProfileId(),
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = uniqueValue + '@example.com',
            UserRoleId = customerSupportRole.Id
        );

        insert assignee;
    }

    @isTest
    static void testExecute() {
        User assignee = [
            SELECT Id
            FROM User
            WHERE LastName = :ASSIGNEE_LAST_NAME
            LIMIT 1
        ];

        insert new UserSkill__c(
            UserId__c = assignee.Id,
            SkillName__c = 'Apex Programming',
            Mastery__c = '5'
        );

        String caseOrigin;

        for (Schema.PicklistEntry entry :Case.Origin.getDescribe().getPicklistValues()) {
            if (entry.isActive()) {
                caseOrigin = entry.getValue();
                break;
            }
        }

        Case testCase = new Case(
            Status = 'Awaiting Assignment',
            Origin = caseOrigin,
            Subject = 'Queueable Assignment Test',
            Description = 'Apex trigger causes SOQL limit exceptions.'
        );

        insert testCase;

        Test.startTest();

        System.enqueueJob(
            new CaseAssignmentQueueable(new Set<Id>{testCase.Id})
        );

        Test.stopTest();

        Case actualCase = [
            SELECT OwnerId
            FROM Case
            WHERE Id = :testCase.Id
        ];

        Assert.areEqual(
            assignee.Id,
            actualCase.OwnerId,
            'Queueable should execute Case assignment orchestration.'
        );
    }
}