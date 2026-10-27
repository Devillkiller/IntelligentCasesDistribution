public with sharing class CaseTriggerHandler {

    @TestVisible
    private static final String STATUS_NEW = 'New';

    @TestVisible
    private static final String STATUS_AWAITING_ASSIGNMENT = 'Awaiting Assignment';

    @TestVisible
    private static CaseTriggerHandler instance;

    public static CaseTriggerHandler getInstance() {
        if (null == instance) {
            instance = new CaseTriggerHandler();
        }
        return instance;
    }

    public void run(List<Case> newCases, Map<Id,Case> oldCasesMap) {
        if (Trigger.isAfter && Trigger.isUpdate) {
            handleAfterUpdate(newCases, oldCasesMap);
        }
    }

    @TestVisible
    private void handleAfterUpdate(List<Case> newCases, Map<Id,Case> oldCasesMap) {
        performSkillBasedAssignment(newCases, oldCasesMap);
    }

    @TestVisible
    private void performSkillBasedAssignment(List<Case> newCases, Map<Id,Case> oldCasesMap) {
        Set<Id> scope = new Set<Id>();

        for (Case newCase : newCases) {
            Case oldCase = oldCasesMap.get(newCase.Id);
            if (
                STATUS_NEW.equalsIgnoreCase(oldCase.Status)
                && STATUS_AWAITING_ASSIGNMENT.equalsIgnoreCase(newCase.Status)
            ) {
                scope.add(newCase.Id);
            }
        }

        if (!scope.isEmpty()) {
            System.enqueueJob(new CaseAssignmentQueueable(scope));
        }
    }
}