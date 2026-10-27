@isTest
private class CaseSelectorTest {

    @isTest
    static void testGetInstance() {
        Assert.isNull(
            CaseSelector.instance,
            'No instance should be created untill .getInstance() method is executed.'
        );

        CaseSelector selector = CaseSelector.getInstance();

        Assert.isNotNull(
            CaseSelector.instance,
            'Instance should be created after .getInstance() method is executed.'
        );

        Assert.areEqual(
            selector,
            CaseSelector.instance,
            'Returned instance should be the same as static one.'
        );
    }

    @isTest
    static void testGetCasesByIds_emptyScope() {
        Integer queriesBeforeCall = Limits.getQueries();

        Map<Id, Case> result = CaseSelector.getInstance().getCasesByIds(
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
    static void testGetCasesByIds() {
        String caseOrigin;

        for (Schema.PicklistEntry entry :Case.Origin.getDescribe().getPicklistValues()) {
            if (entry.isActive()) {
                caseOrigin = entry.getValue();
                break;
            }
        }

        Case caseOne = new Case(
            Status = 'New',
            Origin = caseOrigin,
            Subject = 'Case One',
            Description = 'Case One Description'
        );

        Case caseTwo = new Case(
            Status = 'New',
            Origin = caseOrigin,
            Subject = 'Case Two',
            Description = 'Case Two Description'
        );

        insert new List<Case>{
            caseOne,
            caseTwo
        };

        Map<Id, Case> result = CaseSelector.getInstance().getCasesByIds(
            new Set<Id>{
                caseOne.Id,
                caseTwo.Id
            }
        );

        Assert.areEqual(
            2,
            result.size(),
            'Both requested Cases should be returned.'
        );

        Assert.isTrue(
            result.containsKey(caseOne.Id),
            'First requested Case should be returned.'
        );

        Assert.isTrue(
            result.containsKey(caseTwo.Id),
            'Second requested Case should be returned.'
        );

        Assert.areEqual(
            'Case One Description',
            result.get(caseOne.Id).Description,
            'Case Description should be queried.'
        );

        Assert.areEqual(
            'New',
            result.get(caseOne.Id).Status,
            'Case Status should be queried.'
        );

        Assert.isNotNull(
            result.get(caseOne.Id).OwnerId,
            'Case OwnerId should be queried.'
        );
    }
}