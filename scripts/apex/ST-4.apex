//ST-4 LWC Dev Specialist is expected
Case testCase = new Case(
    Subject = 'AUTO-ST-4',
    Status = 'New',
    Description = 'A custom Lightning Web Component receives a response '
        + 'from an external REST API, but its client-side JavaScript can '
        + 'no longer parse and display the returned data after the response '
        + 'structure changed. The Lightning Web Component response handling '
        + 'and UI rendering logic must be corrected.',
    Origin = 'Email'
);
insert testCase;

testCase.Status = 'Awaiting Assignment';
update testCase;