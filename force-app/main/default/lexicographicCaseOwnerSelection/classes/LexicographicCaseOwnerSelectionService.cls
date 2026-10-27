public with sharing class LexicographicCaseOwnerSelectionService {

    @TestVisible
    private static final Integer MAX_CASES_ASSIGNED = 5;

    @TestVisible
    private Map<Id, Integer> pendingAssignmentsByUserId;

    @TestVisible
    private static LexicographicCaseOwnerSelectionService instance;

    public static LexicographicCaseOwnerSelectionService getInstance() {
        if (null == instance) {
            instance = new LexicographicCaseOwnerSelectionService();
        }
        return instance;
    }

    public Id selectCaseOwner(Set<String> requiredSkills) {
        if (null == requiredSkills || requiredSkills.isEmpty()) {
            return null;
        }

        UserSelector userSelector = UserSelector.getInstance();

        List<User> potentialUsers = userSelector.getPotentialUsers();
        if (null == potentialUsers || potentialUsers.isEmpty()) {
            return null;
        }

        Set<Id> potentialUserIds = new Map<Id, User>(potentialUsers).keySet();

        Map<Id, Integer> openCasesCountByUserId = userSelector.getOpenCasesCountByUserIds(
            potentialUserIds
        );

        List<User> eligibleUsers = getEligibleUsers(potentialUsers, openCasesCountByUserId);

        if (eligibleUsers.isEmpty()) {
            return null;
        }

        Set<Id> eligibleUserIds = new Map<Id, User>(eligibleUsers).keySet();

        Map<Id, List<UserSkill__c>> userSkillsByUserId =
            UserSkillSelector.getInstance().getUserSkillsByUserIds(
                eligibleUserIds
            );

        LexicographicCandidateScoreCalculator calculator =
            LexicographicCandidateScoreCalculator.getInstance();
        LexicographicCandidateScoreComparator comparator =
            LexicographicCandidateScoreComparator.getInstance();
        LexicographicCandidateScore bestCandidate;

        for (User eligibleUser :eligibleUsers) {
            LexicographicCandidateScore candidate =
                calculator.calculate(
                    eligibleUser.Id,
                    requiredSkills,
                    userSkillsByUserId.get(
                        eligibleUser.Id
                    )
                );

            if (
                null == bestCandidate
                || comparator.compare(candidate, bestCandidate) > 0
            ) {
                bestCandidate = candidate;
            }
        }

        if (null == bestCandidate) {
            return null;
        }

        registerPendingAssignment(
            bestCandidate.userId
        );

        return bestCandidate.userId;
    }

    @TestVisible
    private List<User> getEligibleUsers(
        List<User> potentialUsers,
        Map<Id, Integer> openCasesCountByUserId
    ) {

        if (null == pendingAssignmentsByUserId) {
            pendingAssignmentsByUserId = new Map<Id, Integer>();
        }

        List<User> eligibleUsers = new List<User>();

        for (User potentialUser :potentialUsers) {
            Integer openCasesCount = openCasesCountByUserId.get(potentialUser.Id);

            if (null == openCasesCount) {
                openCasesCount = 0;
            }

            Integer pendingAssignmentsCount =
                pendingAssignmentsByUserId.get(
                    potentialUser.Id
                );

            if (null == pendingAssignmentsCount) {
                pendingAssignmentsCount = 0;
            }

            if (
                openCasesCount
                    + pendingAssignmentsCount
                    < MAX_CASES_ASSIGNED
            ) {
                eligibleUsers.add(
                    potentialUser
                );
            }
        }

        return eligibleUsers;
    }

    @TestVisible
    private void registerPendingAssignment(Id userId) {
        if (null == userId) {
            return;
        }

        Integer pendingAssignmentsCount = pendingAssignmentsByUserId.get(userId);

        pendingAssignmentsByUserId.put(
            userId,
            null == pendingAssignmentsCount ? 1 : pendingAssignmentsCount + 1
        );
    }
}