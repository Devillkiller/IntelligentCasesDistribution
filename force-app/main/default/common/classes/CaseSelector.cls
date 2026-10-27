public inherited sharing class CaseSelector {

    @TestVisible
    private static CaseSelector instance;

    public static CaseSelector getInstance() {
        if (null == instance) {
            instance = new CaseSelector();
        }
        return instance;
    }

    public Map<Id, Case> getCasesByIds(Set<Id> caseIds) {

        if (null == caseIds || caseIds.isEmpty()) {
            return new Map<Id, Case>();
        }

        return new Map<Id, Case>([
            SELECT
                Id,
                Status,
                Description,
                OwnerId
            FROM Case
            WHERE Id IN :caseIds
        ]);
    }
}