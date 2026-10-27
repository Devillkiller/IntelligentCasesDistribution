@isTest
private class CaseAssignmentServiceTest {

    private static final String ASSIGNEE_LAST_NAME = 'COMMON_ASSIGNMENT_USER';

    @TestSetup
    static void setupData() {
        UserRole customerSupportRole = new UserRole(
            Name = 'Unit Test Customer Support Common'
        );

        insert customerSupportRole;

        String uniqueValue = ASSIGNEE_LAST_NAME + '.' + DateTime.now().getTime();

        User assignee = new User(
            Alias = 'cmnasgn',
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
    static void testGetInstance() {
        Assert.isNull(
            CaseAssignmentService.instance,
            'No instance should be created untill .getInstance() method is executed.'
        );

        CaseAssignmentService service = CaseAssignmentService.getInstance();

        Assert.isNotNull(
            CaseAssignmentService.instance,
            'Instance should be created after .getInstance() method is executed.'
        );

        Assert.areEqual(
            service,
            CaseAssignmentService.instance,
            'Returned instance should be the same as static one.'
        );
    }

    @isTest
    static void testAssignCases_emptyScope() {
        Integer queriesBeforeCall = Limits.getQueries();

        CaseAssignmentService.getInstance().assignCases(
            new Set<Id>()
        );

        Assert.areEqual(
            queriesBeforeCall,
            Limits.getQueries(),
            'No SOQL queries should be executed for an empty Case scope.'
        );
    }

    @isTest
    static void testAssignCases_nonAwaitingAssignmentCase() {
        String caseOrigin;

        for (Schema.PicklistEntry entry :Case.Origin.getDescribe().getPicklistValues()) {
            if (entry.isActive()) {
                caseOrigin = entry.getValue();
                break;
            }
        }

        Case testCase = new Case(
            Status = 'New',
            Origin = caseOrigin,
            Subject = 'Case Not Ready For Assignment',
            Description = 'Apex trigger issue'
        );

        insert testCase;

        Id originalOwnerId = [
            SELECT OwnerId
            FROM Case
            WHERE Id = :testCase.Id
        ].OwnerId;

        CaseAssignmentService.getInstance().assignCases(
            new Set<Id>{ testCase.Id }
        );

        Case actualCase = [
            SELECT OwnerId
            FROM Case
            WHERE Id = :testCase.Id
        ];

        Assert.areEqual(
            originalOwnerId,
            actualCase.OwnerId,
            'Case outside Awaiting Assignment status should not be reassigned.'
        );
    }

    @isTest
    static void testAssignCases_noRequiredSkills() {
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
            Subject = 'Case Without Required Skills',
            Description = 'Test Description'
        );

        insert testCase;

        Id originalOwnerId = [
            SELECT OwnerId
            FROM Case
            WHERE Id = :testCase.Id
        ].OwnerId;

        SkillSelector.instance = null;

        SkillSelector skillSelector = SkillSelector.getInstance();

        skillSelector.skills = new Set<String>{
            'API Integration'
        };

        CaseAssignmentService.getInstance().assignCases(
            new Set<Id>{testCase.Id}
        );

        Case actualCase = [
            SELECT OwnerId
            FROM Case
            WHERE Id = :testCase.Id
        ];

        Assert.areEqual(
            originalOwnerId,
            actualCase.OwnerId,
            'Case should not be reassigned when no required skills are identified.'
        );
    }

    @isTest
    static void testAssignCases_noEligibleUser() {
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
            Subject = 'Case Without Eligible User',
            Description = 'Apex trigger issue'
        );

        insert testCase;

        Id originalOwnerId = [
            SELECT OwnerId
            FROM Case
            WHERE Id = :testCase.Id
        ].OwnerId;

        UserSelector.instance = null;

        UserSelector userSelector = UserSelector.getInstance();

        userSelector.potentialUsersMemo = new List<User>();

        CaseAssignmentService.getInstance().assignCases(
            new Set<Id>{testCase.Id}
        );

        Case actualCase = [
            SELECT OwnerId
            FROM Case
            WHERE Id = :testCase.Id
        ];

        Assert.areEqual(
            originalOwnerId,
            actualCase.OwnerId,
            'Case should not be reassigned when no eligible user is available.'
        );
    }

    @isTest
    static void testAssignCases_successfulAssignment() {
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
            Subject = 'Apex Assignment Case',
            Description = 'A newly deployed Apex trigger causes '
                + 'SOQL limit exceptions and needs debugging.'
        );

        insert testCase;

        ContentVersion attachment = new ContentVersion(
            Title = 'Debug Log',
            PathOnClient = 'DebugLog.txt',
            VersionData = Blob.valueOf(
                'System.LimitException: Too many SOQL queries: 101'
            ),
            FirstPublishLocationId = testCase.Id
        );

        insert attachment;

        CaseAssignmentService.getInstance().assignCases(
            new Set<Id>{testCase.Id}
        );

        Case actualCase = [
            SELECT OwnerId
            FROM Case
            WHERE Id = :testCase.Id
        ];

        Assert.areEqual(
            assignee.Id,
            actualCase.OwnerId,
            'Case should be assigned to the user selected by the lexicographic '
                + 'assignment service.'
        );
    }
}