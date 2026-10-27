public inherited sharing class CaseAttachmentSelector {

    @TestVisible
    private static CaseAttachmentSelector instance;

    public static CaseAttachmentSelector getInstance() {
        if (null == instance) {
            instance = new CaseAttachmentSelector();
        }
        return instance;
    }

    public Map<Id, List<ContentDocument>> getCaseAttachmentsByCaseIds(Set<Id> caseIds) {
        Map<Id, List<ContentDocument>> result = new Map<Id, List<ContentDocument>>();

        if (null == caseIds || caseIds.isEmpty()) {
            return result;
        }

        for (Id caseId : caseIds) {
            result.put(caseId, new List<ContentDocument>());
        }

        for (ContentDocumentLink documentLink : [
            SELECT
                LinkedEntityId,
                ContentDocumentId,
                ContentDocument.CreatedDate
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :caseIds
            ORDER BY
                LinkedEntityId,
                ContentDocument.CreatedDate DESC,
                ContentDocumentId
        ]) {
            result
                .get(documentLink.LinkedEntityId)
                .add(
                    new ContentDocument(
                        Id = documentLink.ContentDocumentId
                    )
                );
        }

        return result;
    }
}