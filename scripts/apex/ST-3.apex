//ST-3 Service Admin Specialist is expected
Case testCase = new Case(
    Subject = 'AUTO-ST-3',
    Status = 'New',
    Description = 'Newly created Cases remain unassigned instead of being '
        + 'routed through Omni-Channel. Relevant Knowledge articles are also '
        + 'not suggested while the Cases are being processed. The '
        + 'Omni-Channel Case routing and Knowledge article suggestion '
        + 'behavior must be corrected.',
    Origin = 'Email'
);
insert testCase;

testCase.Status = 'Awaiting Assignment';
update testCase;