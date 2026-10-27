public inherited sharing class UserSelector {

    @TestVisible
    private static final String USER_ROLE_NAME_MATCHER_CUSTOMER_SUPPORT
        = '%Customer Support%';

    @TestVisible
    private static final String FIELD_API_NAME_OWNER_ID = 'OwnerId';

    @TestVisible
    private static final String ALIAS_OPEN_CASES_COUNT = 'openCasesCount';

    @TestVisible
    private List<User> potentialUsersMemo;

    @TestVisible
    private Map<Id, Integer> openCasesCountByUserIdMemo = new Map<Id, Integer>();

    @TestVisible
    private static UserSelector instance;

    public static UserSelector getInstance() {
        if (null == instance) {
            instance = new UserSelector();
        }
        return instance;
    }

    public List<User> getPotentialUsers() {
        if (null != potentialUsersMemo) {
            return potentialUsersMemo;
        }

        potentialUsersMemo = [
            SELECT Id, Name, Email
            FROM User
            WHERE IsActive = TRUE
                AND UserRole.Name LIKE :USER_ROLE_NAME_MATCHER_CUSTOMER_SUPPORT
            ORDER BY Id
        ];

        return potentialUsersMemo;
    }

    public Map<Id, Integer> getOpenCasesCountByUserIds(Set<Id> userIds) {
        Map<Id, Integer> result = new Map<Id, Integer>();

        if (null == userIds || userIds.isEmpty()) {
            return result;
        }

        Set<Id> usersToQuery = new Set<Id>();

        for (Id userId :userIds) {
            if (openCasesCountByUserIdMemo.containsKey(userId)) {
                result.put(
                    userId,
                    openCasesCountByUserIdMemo.get(userId)
                );
            } else {
                usersToQuery.add(userId);
            }
        }

        if (!usersToQuery.isEmpty()) {
            for (Id userId :usersToQuery) {
                openCasesCountByUserIdMemo.put(userId, 0);
            }

            for (AggregateResult ar :[
                SELECT OwnerId, COUNT(Id) openCasesCount
                FROM Case
                WHERE IsClosed = FALSE
                    AND OwnerId IN :usersToQuery
                GROUP BY OwnerId
            ]) {
                openCasesCountByUserIdMemo.put(
                    (Id) ar.get(FIELD_API_NAME_OWNER_ID),
                    (Integer) ar.get(ALIAS_OPEN_CASES_COUNT)
                );
            }

            for (Id userId :usersToQuery) {
                result.put(
                    userId,
                    openCasesCountByUserIdMemo.get(userId)
                );
            }
        }

        return result;
    }
}