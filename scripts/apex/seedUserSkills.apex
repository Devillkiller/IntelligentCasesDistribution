final String DEMO_EMAIL = 'test@test.com';
final String TEST_USER_ROLE_NAME = 'Task Distribution Customer Support';

final Map<String, Map<String, String>> USER_SKILLS_BY_NAME =
    new Map<String, Map<String, String>>{
        'Apex Dev Specialist' => new Map<String, String>{
            'Integrations Architecture' => '1',
            'Data Modeling (Technical)' => '2',
            'Apex Programming' => '4',
            'DevOps & CI/CD' => '2',
            'Lightning Web Components' => '2',
            'Apex Unit Testing' => '4',
            'Debugging & Logs' => '4',
            'Performance & Limits' => '3',
            'Salesforce APIs' => '2',
            'Code Quality & Refactoring' => '3'
        },
        'Admin Dev Specialist' => new Map<String, String>{
            'Debugging & Logs' => '1',
            'Integrations Architecture' => '1',
            'Data Management' => '2',
            'Security Model' => '3',
            'Apex Programming' => '1',
            'Code Quality & Refactoring' => '1',
            'Data Modeling (Technical)' => '1',
            'Change Management' => '2',
            'User Training & Support' => '2',
            'Apex Unit Testing' => '1',
            'Knowledge Management' => '2',
            'Performance & Limits' => '1',
            'Lightning Web Components' => '1',
            'Salesforce APIs' => '1',
            'Reporting & Dashboards' => '2',
            'Object & Field Configuration' => '2',
            'Case Management' => '3',
            'Omni-Channel Routing' => '2'
        },
        'Dev Admin Specialist' => new Map<String, String>{
            'Integrations Architecture' => '2',
            'Case Management' => '1',
            'Change Management' => '1',
            'Performance & Limits' => '2',
            'Apex Unit Testing' => '3',
            'User Training & Support' => '1',
            'Data Modeling (Technical)' => '2',
            'Omni-Channel Routing' => '1',
            'Reporting & Dashboards' => '1',
            'Object & Field Configuration' => '1',
            'Knowledge Management' => '1',
            'Apex Programming' => '3',
            'Debugging & Logs' => '3',
            'Code Quality & Refactoring' => '2',
            'Lightning Web Components' => '3',
            'Flow Automation' => '1',
            'Salesforce APIs' => '2',
            'Security Model' => '1',
            'DevOps & CI/CD' => '2',
            'Data Management' => '1'
        },
        'LWC Dev Specialist' => new Map<String, String>{
            'DevOps & CI/CD' => '2',
            'Apex Programming' => '2',
            'Integrations Architecture' => '3',
            'API Integration' => '3',
            'Debugging & Logs' => '2',
            'Apex Unit Testing' => '2',
            'Code Quality & Refactoring' => '3',
            'Lightning Web Components' => '4',
            'UI Customization' => '4',
            'Performance & Limits' => '2',
            'Salesforce APIs' => '3',
            'Data Modeling (Technical)' => '2'
        },
        'Security Admin Specialist' => new Map<String, String>{
            'Data Management' => '2',
            'Case Management' => '2',
            'Knowledge Management' => '1',
            'Omni-Channel Routing' => '1',
            'Security Model' => '4',
            'User Access & Permissions' => '4',
            'Data Security' => '4',
            'Reporting & Dashboards' => '2',
            'Flow Automation' => '3',
            'Object & Field Configuration' => '3',
            'Change Management' => '1',
            'User Training & Support' => '1'
        },
        'Service Admin Specialist' => new Map<String, String>{
            'Data Management' => '1',
            'Case Management' => '4',
            'Knowledge Management' => '3',
            'Security Model' => '2',
            'Flow Automation' => '2',
            'Object & Field Configuration' => '2',
            'Reporting & Dashboards' => '2',
            'Change Management' => '2',
            'User Training & Support' => '3',
            'Omni-Channel Routing' => '3',
            'Debugging & Logs' => '2'
        }
    };

List<String> logicalUserNames =
    new List<String>(USER_SKILLS_BY_NAME.keySet());
logicalUserNames.sort();

Map<String, Id> userIdByName = new Map<String, Id>();

for (User testUser :[
    SELECT Id, Name
    FROM User
    WHERE Email = :DEMO_EMAIL
        AND IsActive = TRUE
        AND UserRole.Name = :TEST_USER_ROLE_NAME
]) {
    if (USER_SKILLS_BY_NAME.containsKey(testUser.Name)) {
        userIdByName.put(
            testUser.Name,
            testUser.Id
        );
    }
}

System.assertEquals(
    logicalUserNames.size(),
    userIdByName.size(),
    'Expected test users were not found. Run seedUsers.apex first.'
);

Set<Id> testUserIds =
    new Set<Id>(userIdByName.values());

List<UserSkill__c> existingSkills = [
    SELECT Id
    FROM UserSkill__c
    WHERE UserId__c IN :testUserIds
];

if (!existingSkills.isEmpty()) {
    delete existingSkills;
    Database.emptyRecycleBin(existingSkills);
}

List<UserSkill__c> skillsToInsert =
    new List<UserSkill__c>();

for (String logicalUserName :logicalUserNames) {
    Id userId =
        userIdByName.get(
            logicalUserName
        );

    Map<String, String> skillsByName =
        USER_SKILLS_BY_NAME.get(
            logicalUserName
        );

    List<String> skillNames =
        new List<String>(skillsByName.keySet());
    skillNames.sort();

    for (String skillName :skillNames) {
        skillsToInsert.add(
            new UserSkill__c(
                UserId__c = userId,
                SkillName__c = skillName,
                Mastery__c = skillsByName.get(
                    skillName
                )
            )
        );
    }
}

insert skillsToInsert;

System.debug(
    LoggingLevel.INFO,
    '# of inserted UserSkill__c records: '
        + skillsToInsert.size()
);

System.debug(
    LoggingLevel.INFO,
    'Test skill dataset creation completed successfully.'
);