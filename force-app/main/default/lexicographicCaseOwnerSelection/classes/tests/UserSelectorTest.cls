@isTest
private class UserSelectorTest {

    private static final String CUSTOMER_SUPPORT_USER_ONE_LAST_NAME =
        'CustomerSupportUserOne';

    private static final String CUSTOMER_SUPPORT_USER_TWO_LAST_NAME =
        'CustomerSupportUserTwo';

    private static final String OTHER_USER_LAST_NAME =
        'OtherUser';

    @TestSetup
    static void setupTestData() {
        UserRole customerSupportRole = new UserRole(
            Name = 'Unit Test Customer Support'
        );

        UserRole otherRole = new UserRole(
            Name = 'Unit Test Other Role'
        );

        insert new List<UserRole>{
            customerSupportRole,
            otherRole
        };

        insert new List<User>{
            createUser(
                CUSTOMER_SUPPORT_USER_ONE_LAST_NAME,
                customerSupportRole.Id,
                1
            ),
            createUser(
                CUSTOMER_SUPPORT_USER_TWO_LAST_NAME,
                customerSupportRole.Id,
                2
            ),
            createUser(
                OTHER_USER_LAST_NAME,
                otherRole.Id,
                3
            )
        };
    }

    @isTest
    static void testGetInstance() {
        Assert.isNull(
            UserSelector.instance,
            'No instance should be created until .getInstance() method is executed.'
        );

        UserSelector selector =
            UserSelector.getInstance();

        Assert.isNotNull(
            UserSelector.instance,
            'Instance should be created after .getInstance() method is executed.'
        );

        Assert.areEqual(
            selector,
            UserSelector.instance,
            'Returned instance should be the same as static one.'
        );
    }

    @isTest
    static void testGetPotentialUsers() {
        User customerSupportUserOne =
            getUserByLastName(
                CUSTOMER_SUPPORT_USER_ONE_LAST_NAME
            );

        User customerSupportUserTwo =
            getUserByLastName(
                CUSTOMER_SUPPORT_USER_TWO_LAST_NAME
            );

        User otherUser =
            getUserByLastName(
                OTHER_USER_LAST_NAME
            );

        List<User> potentialUsers =
            UserSelector.getInstance().getPotentialUsers();

        Set<Id> potentialUserIds =
            new Map<Id, User>(
                potentialUsers
            ).keySet();

        Assert.isTrue(
            potentialUserIds.contains(
                customerSupportUserOne.Id
            ),
            'Active user with Customer Support role should be returned.'
        );

        Assert.isTrue(
            potentialUserIds.contains(
                customerSupportUserTwo.Id
            ),
            'Another active user with Customer Support role should be returned.'
        );

        Assert.isFalse(
            potentialUserIds.contains(
                otherUser.Id
            ),
            'User without Customer Support role should not be returned.'
        );
    }

    @isTest
    static void testGetPotentialUsers_memoization() {
        UserSelector selector =
            UserSelector.getInstance();

        List<User> firstResult =
            selector.getPotentialUsers();

        Integer queriesAfterFirstCall =
            Limits.getQueries();

        List<User> secondResult =
            selector.getPotentialUsers();

        Integer queriesAfterSecondCall =
            Limits.getQueries();

        Assert.areEqual(
            queriesAfterFirstCall,
            queriesAfterSecondCall,
            'Repeated call should use memoized users without additional SOQL query.'
        );

        Assert.areEqual(
            firstResult,
            secondResult,
            'Repeated call should return the memoized users.'
        );
    }

    @isTest
    static void testGetOpenCasesCountByUserIds() {
        User userOne =
            getUserByLastName(
                CUSTOMER_SUPPORT_USER_ONE_LAST_NAME
            );

        User userTwo =
            getUserByLastName(
                CUSTOMER_SUPPORT_USER_TWO_LAST_NAME
            );

        String openStatus =
            getOpenCaseStatus();

        String caseOrigin =
            getCaseOrigin();

        insert new List<Case>{
            createCase(
                userOne.Id,
                openStatus,
                caseOrigin
            ),
            createCase(
                userOne.Id,
                openStatus,
                caseOrigin
            ),
            createCase(
                userOne.Id,
                openStatus,
                caseOrigin
            )
        };

        Map<Id, Integer> openCasesCountByUserId =
            UserSelector.getInstance().getOpenCasesCountByUserIds(
                new Set<Id>{
                    userOne.Id,
                    userTwo.Id
                }
            );

        Assert.areEqual(
            3,
            openCasesCountByUserId.get(
                userOne.Id
            ),
            'User with three open Cases should have count equal to three.'
        );

        Assert.areEqual(
            0,
            openCasesCountByUserId.get(
                userTwo.Id
            ),
            'User without open Cases should have count equal to zero.'
        );
    }

    @isTest
    static void testGetOpenCasesCountByUserIds_emptySet() {
        Integer queriesBeforeCall =
            Limits.getQueries();

        Map<Id, Integer> result =
            UserSelector.getInstance().getOpenCasesCountByUserIds(
                new Set<Id>()
            );

        Integer queriesAfterCall = Limits.getQueries();

        Assert.isTrue(
            result.isEmpty(),
            'Empty user Id set should return an empty map.'
        );

        Assert.areEqual(
            queriesBeforeCall,
            queriesAfterCall,
            'Empty user Id set should not execute SOQL.'
        );
    }

    @isTest
    static void testGetOpenCasesCountByUserIds_memoization() {
        User userOne = getUserByLastName(
            CUSTOMER_SUPPORT_USER_ONE_LAST_NAME
        );

        UserSelector selector = UserSelector.getInstance();

        Map<Id, Integer> firstResult =
            selector.getOpenCasesCountByUserIds(
                new Set<Id>{
                    userOne.Id
                }
            );

        Integer queriesAfterFirstCall = Limits.getQueries();

        Map<Id, Integer> secondResult =
            selector.getOpenCasesCountByUserIds(
                new Set<Id>{
                    userOne.Id
                }
            );

        Integer queriesAfterSecondCall = Limits.getQueries();

        Assert.areEqual(
            queriesAfterFirstCall,
            queriesAfterSecondCall,
            'Repeated call for the same user should not execute an additional SOQL query.'
        );

        Assert.areEqual(
            firstResult.get(userOne.Id),
            secondResult.get(userOne.Id),
            'Repeated call should return the memoized open Case count.'
        );
    }

    @isTest
    static void testGetOpenCasesCountByUserIds_partialMemoization() {
        User userOne = getUserByLastName(
            CUSTOMER_SUPPORT_USER_ONE_LAST_NAME
        );

        User userTwo = getUserByLastName(
            CUSTOMER_SUPPORT_USER_TWO_LAST_NAME
        );

        UserSelector selector = UserSelector.getInstance();

        selector.getOpenCasesCountByUserIds(
            new Set<Id>{
                userOne.Id
            }
        );

        Integer queriesBeforeSecondCall = Limits.getQueries();

        Map<Id, Integer> result = selector.getOpenCasesCountByUserIds(
            new Set<Id>{
                userOne.Id,
                userTwo.Id
            }
        );

        Integer queriesAfterSecondCall = Limits.getQueries();

        Assert.areEqual(
            queriesBeforeSecondCall + 1,
            queriesAfterSecondCall,
            'Only users missing from memo should require an additional SOQL query.'
        );

        Assert.isTrue(
            result.containsKey(userOne.Id),
            'Result should contain previously memoized user.'
        );

        Assert.isTrue(
            result.containsKey(userTwo.Id),
            'Result should contain newly queried user.'
        );
    }

    private static User createUser(
        String lastName,
        Id roleId,
        Integer index
    ) {
        String uniqueValue = String.valueOf(DateTime.now().getTime()) + String.valueOf(index);

        return new User(
            Alias = 'usr' + index,
            Email = 'test' + uniqueValue + '@example.com',
            EmailEncodingKey = 'UTF-8',
            IsActive = true,
            LanguageLocaleKey = 'en_US',
            LastName = lastName,
            LocaleSidKey = 'en_US',
            ProfileId = UserInfo.getProfileId(),
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'test' + uniqueValue + '@example.com',
            UserRoleId = roleId
        );
    }

    private static User getUserByLastName(
        String lastName
    ) {
        return [
            SELECT Id, LastName
            FROM User
            WHERE LastName = :lastName
            LIMIT 1
        ];
    }

    private static Case createCase(
        Id ownerId,
        String status,
        String origin
    ) {
        return new Case(
            OwnerId = ownerId,
            Status = status,
            Origin = origin,
            Subject = 'Unit Test Case'
        );
    }

    private static String getOpenCaseStatus() {
        return [
            SELECT MasterLabel
            FROM CaseStatus
            WHERE IsClosed = FALSE
            LIMIT 1
        ].MasterLabel;
    }

    private static String getCaseOrigin() {
        for (Schema.PicklistEntry entry :Case.Origin.getDescribe().getPicklistValues()) {
            if (entry.isActive()) {
                return entry.getValue();
            }
        }
        return null;
    }
}