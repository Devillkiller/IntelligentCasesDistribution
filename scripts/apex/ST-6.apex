//ST-6 Dev Admin Specialist is expected
Case testCase = new Case(
    Subject = 'AUTO-ST-6',
    Status = 'New',
    Description = 'A new release includes changes to an Apex service and a '
        + 'record-triggered Flow. The deployment pipeline now fails because '
        + 'several Apex tests no longer pass, and the Flow must also be updated '
        + 'to support the new processing logic. The implementation, tests, and '
        + 'deployment configuration need to be corrected.',
    Origin = 'Email'
);
insert testCase;

testCase.Status = 'Awaiting Assignment';
update testCase;
