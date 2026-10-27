public with sharing class CaseAssignmentQueueable implements Queueable, Database.AllowsCallouts {

    private Set<Id> caseIds;

    public CaseAssignmentQueueable(Set<Id> caseIds) {
        this.caseIds = caseIds;
    }

    public void execute(QueueableContext context) {
        CaseAssignmentService.getInstance().assignCases(caseIds);
    }
}