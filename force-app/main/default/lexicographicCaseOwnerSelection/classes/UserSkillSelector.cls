public inherited sharing class UserSkillSelector {

    @TestVisible
    private Map<Id, List<UserSkill__c>> userSkillsByUserIdMemo =
        new Map<Id, List<UserSkill__c>>();

    @TestVisible
    private static UserSkillSelector instance;

    public static UserSkillSelector getInstance() {
        if (null == instance) {
            instance = new UserSkillSelector();
        }

        return instance;
    }

    public Map<Id, List<UserSkill__c>> getUserSkillsByUserIds(
        Set<Id> eligibleUserIds
    ) {

        if (null == eligibleUserIds || eligibleUserIds.isEmpty()) {
            return new Map<Id, List<UserSkill__c>>();
        }

        Map<Id, List<UserSkill__c>> result =
            new Map<Id, List<UserSkill__c>>();
        Set<Id> usersToQuery = new Set<Id>();
        for (Id userId :eligibleUserIds) {
            if (userSkillsByUserIdMemo.containsKey(userId)) {
                result.put(
                    userId,
                    userSkillsByUserIdMemo.get(userId)
                );
            } else {
                usersToQuery.add(userId);
            }
        }

        if (usersToQuery.isEmpty()) {
            return result;
        }

        Map<Id, List<UserSkill__c>> queriedSkillsByUserId =
            new Map<Id, List<UserSkill__c>>();

        for (Id userId :usersToQuery) {
            queriedSkillsByUserId.put(userId, new List<UserSkill__c>());
        }

        for (UserSkill__c userSkill :[
            SELECT
                UserId__c,
                SkillName__c,
                Mastery__c
            FROM UserSkill__c
            WHERE UserId__c IN :usersToQuery
            ORDER BY
                UserId__c,
                SkillName__c
        ]) {
            queriedSkillsByUserId.get(userSkill.UserId__c).add(userSkill);
        }

        for (Id userId :usersToQuery) {
            List<UserSkill__c> userSkills = queriedSkillsByUserId.get(userId);
            userSkillsByUserIdMemo.put(userId, userSkills);
            result.put(userId, userSkills);
        }

        return result;
    }
}