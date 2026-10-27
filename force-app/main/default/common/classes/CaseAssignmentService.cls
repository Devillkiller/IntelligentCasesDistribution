public with sharing class CaseAssignmentService {

    @TestVisible
    private static final String STATUS_AWAITING_ASSIGNMENT = 'Awaiting Assignment';

    @TestVisible
    private static CaseAssignmentService instance;

    public static CaseAssignmentService getInstance() {
        if (null == instance) {
            instance = new CaseAssignmentService();
        }
        return instance;
    }

    public void assignCases(Set<Id> caseIds) {
        if (null == caseIds || caseIds.isEmpty()) {
            return;
        }

        Map<Id, Case> casesById = CaseSelector.getInstance().getCasesByIds(caseIds);

        if (casesById.isEmpty()) {
            return;
        }

        Map<Id, List<ContentDocument>> attachmentsByCaseId =
            CaseAttachmentSelector.getInstance().getCaseAttachmentsByCaseIds(
                casesById.keySet()
            );

        List<Case> casesToUpdate = new List<Case>();

        for (Id caseId : caseIds) {
            Case caseToAssign = casesById.get(caseId);

            if (null == caseToAssign || STATUS_AWAITING_ASSIGNMENT != caseToAssign.Status) {
                continue;
            }

            ContentDocument caseAttachment = getAttachment(
                attachmentsByCaseId.get(
                    caseId
                )
            );

            Set<String> requiredSkills =
                AgentforceSkillsExtractionService.getInstance().getRequiredSkills(
                    caseToAssign,
                    caseAttachment
                );

            if (null == requiredSkills || requiredSkills.isEmpty()) {
                continue;
            }

            Id selectedOwnerId =
                LexicographicCaseOwnerSelectionService.getInstance().selectCaseOwner(
                    requiredSkills
                );

            if (null == selectedOwnerId) {
                continue;
            }

            casesToUpdate.add(
                new Case(
                    Id = caseId,
                    OwnerId = selectedOwnerId
                )
            );
        }

        if (!casesToUpdate.isEmpty()) {
            update casesToUpdate;
        }
    }

    private static ContentDocument getAttachment(List<ContentDocument> attachments) {
        return null != attachments &&
            !attachments.isEmpty() ? attachments[0] : null;
    }
}