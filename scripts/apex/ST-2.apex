//ST-2 Security Admin Specialist is expected
Case testCase = new Case(
    Subject = 'AUTO-ST-2',
    Status = 'New',
    Description = 'Users assigned to one business unit can see records '
        + 'owned by another business unit, although the organization-wide '
        + 'sharing model is configured as Private. At the same time, several '
        + 'users cannot edit fields they should have access to. The role '
        + 'hierarchy, sharing configuration, permission sets, and field-level '
        + 'security need to be reviewed and corrected.',
    Origin = 'Email'
);
insert testCase;

testCase.Status = 'Awaiting Assignment';
update testCase;
