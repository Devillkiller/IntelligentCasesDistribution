//ST-5 Admin Dev Specialist is expected
Case testCase = new Case(
    Subject = 'AUTO-ST-5',
    Status = 'New',
    Description = 'Cases created by an external system through the Salesforce API '
        + 'are processed correctly, but some support users cannot access them and '
        + 'the new process has not yet been prepared for rollout to the support '
        + 'team. The Case access configuration, process changes, and user guidance '
        + 'need to be reviewed before the change is released.',
    Origin = 'Email'
);
insert testCase;

testCase.Status = 'Awaiting Assignment';
update testCase;
