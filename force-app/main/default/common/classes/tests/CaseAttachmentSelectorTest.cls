@isTest
private class CaseAttachmentSelectorTest {

    @isTest
    static void testGetInstance() {
        Assert.isNull(
            CaseAttachmentSelector.instance,
            'No instance should be created untill .getInstance() method is executed.'
        );

        CaseAttachmentSelector selector = CaseAttachmentSelector.getInstance();

        Assert.isNotNull(
            CaseAttachmentSelector.instance,
            'Instance should be created after .getInstance() method is executed.'
        );

        Assert.areEqual(
            selector,
            CaseAttachmentSelector.instance,
            'Returned instance should be the same as static one.'
        );
    }

    @isTest
    static void testGetCaseAttachmentsByCaseIds_emptyScope() {
        Integer queriesBeforeCall = Limits.getQueries();

        Map<Id, List<ContentDocument>> result
            = CaseAttachmentSelector.getInstance().getCaseAttachmentsByCaseIds(
                new Set<Id>()
            );

        Assert.isTrue(
            result.isEmpty(),
            'Empty Case Id set should return an empty map.'
        );

        Assert.areEqual(
            queriesBeforeCall,
            Limits.getQueries(),
            'No SOQL queries should be executed for an empty Case Id set.'
        );
    }

    @isTest
    static void testGetCaseAttachmentsByCaseIds() {
        String caseOrigin;

        for (Schema.PicklistEntry entry :Case.Origin.getDescribe().getPicklistValues()) {
            if (entry.isActive()) {
                caseOrigin = entry.getValue();
                break;
            }
        }

        Case caseWithAttachments = new Case(
            Status = 'New',
            Origin = caseOrigin,
            Subject = 'Case With Attachments'
        );

        Case caseWithoutAttachments = new Case(
            Status = 'New',
            Origin = caseOrigin,
            Subject = 'Case Without Attachments'
        );

        insert new List<Case>{
            caseWithAttachments,
            caseWithoutAttachments
        };

        ContentVersion versionOne = new ContentVersion(
            Title = 'Attachment One',
            PathOnClient = 'AttachmentOne.txt',
            VersionData = Blob.valueOf(
                'Attachment One Content'
            ),
            FirstPublishLocationId = caseWithAttachments.Id
        );

        ContentVersion versionTwo = new ContentVersion(
            Title = 'Attachment Two',
            PathOnClient = 'AttachmentTwo.txt',
            VersionData = Blob.valueOf(
                'Attachment Two Content'
            ),
            FirstPublishLocationId = caseWithAttachments.Id
        );

        insert new List<ContentVersion>{
            versionOne,
            versionTwo
        };

        Set<Id> contentVersionIds =
            new Set<Id>{
                versionOne.Id,
                versionTwo.Id
            };

        Set<Id> expectedContentDocumentIds = new Set<Id>();

        for (ContentVersion version :[
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE Id IN :contentVersionIds
        ]) {
            expectedContentDocumentIds.add(
                version.ContentDocumentId
            );
        }

        Map<Id, List<ContentDocument>> result =
            CaseAttachmentSelector.getInstance().getCaseAttachmentsByCaseIds(
                new Set<Id>{
                    caseWithAttachments.Id,
                    caseWithoutAttachments.Id
                }
            );

        Assert.areEqual(
            2,
            result.size(),
            'Result should contain an entry for every requested Case.'
        );

        Assert.areEqual(
            2,
            result.get(caseWithAttachments.Id).size(),
            'Case with two attachments should contain both ContentDocuments.'
        );

        Set<Id> actualContentDocumentIds =
            new Map<Id, ContentDocument>(
                result.get(
                    caseWithAttachments.Id
                )
            ).keySet();

        Assert.areEqual(
            expectedContentDocumentIds,
            actualContentDocumentIds,
            'Returned ContentDocuments should match documents linked to the Case.'
        );

        Assert.isTrue(
            result.get(
                caseWithoutAttachments.Id
            ).isEmpty(),
            'Case without attachments should contain an empty ContentDocument list.'
        );
    }
}