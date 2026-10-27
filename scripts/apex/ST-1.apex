//ST-1 Apex Dev Specialist is expected
Case testCase = new Case(
    Subject = 'AUTO-ST-1',
    Status = 'New',
    Description = 'An Apex trigger fails with System.LimitException: '
        + 'Too many SOQL queries: 101 during record processing. '
        + 'The issue must be investigated using Apex debug logs, '
        + 'the SOQL governor limit violation in the Apex code must be corrected, '
        + 'and the fix must be verified with Apex unit tests.',
    Origin = 'Email'
);
insert testCase;

testCase.Status = 'Awaiting Assignment';
update testCase;