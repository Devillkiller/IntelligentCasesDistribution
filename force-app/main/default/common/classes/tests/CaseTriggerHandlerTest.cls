@isTest
private class CaseTriggerHandlerTest {

    @isTest
    static void testGetInstance() {
        Assert.isNull(
            CaseTriggerHandler.instance,
            'No instance should be created untill .getInstance() method is executed.'
        );

        CaseTriggerHandler handler =
            CaseTriggerHandler.getInstance();

        Assert.isNotNull(
            CaseTriggerHandler.instance,
            'Instance should be created after .getInstance() method is executed.'
        );

        Assert.areEqual(
            handler,
            CaseTriggerHandler.instance,
            'Returned instance should be the same as static one.'
        );
    }

    @isTest
    static void testNewToAwaitingAssignment_enqueuesJob() {
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
            Subject = 'Trigger Assignment Case One',
            Description = 'Test Description'
        );

        Case caseTwo = new Case(
            Status = 'New',
            Origin = caseOrigin,
            Subject = 'Trigger Assignment Case Two',
            Description = 'Test Description'
        );

        insert new List<Case>{
            caseOne,
            caseTwo
        };

        caseOne.Status = 'Awaiting Assignment';

        caseTwo.Status = 'Awaiting Assignment';

        Test.startTest();

        update new List<Case>{
            caseOne,
            caseTwo
        };

        Assert.areEqual(
            1,
            Limits.getQueueableJobs(),
            'A single Queueable job should be created for all Cases in the trigger scope.'
        );

        Test.stopTest();
    }

    @isTest
    static void testNoStatusTransition_doesNotEnqueueJob() {
        String caseOrigin;

        for (Schema.PicklistEntry entry :Case.Origin.getDescribe().getPicklistValues()) {
            if (entry.isActive()) {
                caseOrigin = entry.getValue();
                break;
            }
        }

        Case testCase = new Case(
            Status = 'New',
            Origin = caseOrigin,
            Subject = 'Original Subject',
            Description = 'Test Description'
        );

        insert testCase;

        testCase.Subject = 'Updated Subject';

        Test.startTest();

        update testCase;

        Assert.areEqual(
            0,
            Limits.getQueueableJobs(),
            'Queueable job should not be created when Case does not transition from '
                + 'New to Awaiting Assignment.'
        );

        Test.stopTest();
    }

    @isTest
    static void testAlreadyAwaitingAssignment_doesNotEnqueueJob() {
        String caseOrigin;

        for (Schema.PicklistEntry entry :Case.Origin.getDescribe().getPicklistValues()) {
            if (entry.isActive()) {
                caseOrigin = entry.getValue();
                break;
            }
        }

        Case testCase = new Case(
            Status = 'Awaiting Assignment',
            Origin = caseOrigin,
            Subject = 'Awaiting Assignment Case',
            Description = 'Test Description'
        );

        insert testCase;

        testCase.Subject = 'Updated Subject';

        Test.startTest();

        update testCase;

        Assert.areEqual(
            0,
            Limits.getQueueableJobs(),
            'Case already in Awaiting Assignment status should not enqueue another '
                + 'assignment job.'
        );

        Test.stopTest();
    }
}