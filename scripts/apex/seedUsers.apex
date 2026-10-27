final String DEMO_EMAIL = 'test@test.com';
final String CUSTOMER_SUPPORT_ROLE_NAME = 'Task Distribution Customer Support';

final List<String> LOGICAL_USER_NAMES = new List<String>{
    'Admin Dev Specialist',
    'Apex Dev Specialist',
    'Dev Admin Specialist',
    'LWC Dev Specialist',
    'Security Admin Specialist',
    'Service Admin Specialist'
};

final Id PLATFORM_LICENSE_ID = [
    SELECT Id
    FROM UserLicense
    WHERE Name = 'Salesforce Platform'
    LIMIT 1
].Id;

final Id STANDARD_PLATFORM_USER_ID = [
    SELECT Id
    FROM Profile
    WHERE Name = 'Standard Platform User'
      AND UserLicenseId = :PLATFORM_LICENSE_ID
    LIMIT 1
].Id;

List<UserRole> customerSupportRoles = [
    SELECT Id
    FROM UserRole
    WHERE Name = :CUSTOMER_SUPPORT_ROLE_NAME
    LIMIT 1
];

Id customerSupportRoleId;
if (customerSupportRoles.isEmpty()) {
    UserRole customerSupportRole = new UserRole(
        Name = CUSTOMER_SUPPORT_ROLE_NAME
    );
    insert customerSupportRole;
    customerSupportRoleId = customerSupportRole.Id;
} else {
    customerSupportRoleId = customerSupportRoles[0].Id;
}

Map<String, List<User>> existingUsersByName = new Map<String, List<User>>();
for (User existingUser :[
    SELECT
        Id,
        Name,
        IsActive,
        UserRoleId
    FROM User
    WHERE Email = :DEMO_EMAIL
    ORDER BY CreatedDate ASC
]) {
    if (!LOGICAL_USER_NAMES.contains(existingUser.Name)) {
        continue;
    }

    if (!existingUsersByName.containsKey(existingUser.Name)) {
        existingUsersByName.put(
            existingUser.Name,
            new List<User>()
        );
    }

    existingUsersByName.get(existingUser.Name).add(existingUser);
}

List<User> usersToDeactivate = new List<User>();
List<User> usersToUpdate = new List<User>();
List<User> usersToInsert = new List<User>();
Long timestamp = DateTime.now().getTime();

for (String logicalUserName :LOGICAL_USER_NAMES) {
    List<User> existingUsers = existingUsersByName.get(logicalUserName);

    if (null != existingUsers && !existingUsers.isEmpty()) {
        User primaryUser = existingUsers[0];
        primaryUser.IsActive = true;
        primaryUser.UserRoleId = customerSupportRoleId;
        usersToUpdate.add(primaryUser);

        for (Integer i = 1; i < existingUsers.size(); i++) {
            if (existingUsers[i].IsActive) {
                existingUsers[i].IsActive = false;
                usersToDeactivate.add(existingUsers[i]);
            }
        }

        continue;
    }

    Integer lastSpaceIndex = logicalUserName.lastIndexOf(' ');

    String firstName = '';
    String lastName = logicalUserName;

    if (lastSpaceIndex > 0) {
        firstName = logicalUserName.substring(0, lastSpaceIndex);
        lastName = logicalUserName.substring(lastSpaceIndex + 1);
    }

    String usernameBase = logicalUserName.replace(' ', '');
    String aliasValue = usernameBase.length() > 8
        ? usernameBase.substring(0, 8)
        : usernameBase;

    usersToInsert.add(new User(
        FirstName = firstName,
        LastName = lastName,
        Email = DEMO_EMAIL,
        Username = usernameBase + '.' + timestamp + '@example.test',
        Alias = aliasValue,
        TimeZoneSidKey = 'Europe/Kyiv',
        LocaleSidKey = 'en_US',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US',
        ProfileId = STANDARD_PLATFORM_USER_ID,
        UserRoleId = customerSupportRoleId,
        UserPermissionsSFContentUser = false
    ));
}

if (!usersToDeactivate.isEmpty()) {
    update usersToDeactivate;
}

if (!usersToUpdate.isEmpty()) {
    update usersToUpdate;
}

if (!usersToInsert.isEmpty()) {
    insert usersToInsert;
}

System.debug(
    LoggingLevel.INFO,
    '# of inserted Users: ' + usersToInsert.size()
);
System.debug(
    LoggingLevel.INFO,
    '# of updated Users: ' + usersToUpdate.size()
);
System.debug(
    LoggingLevel.INFO,
    '# of deactivated duplicate Users: ' + usersToDeactivate.size()
);
System.debug(
    LoggingLevel.INFO,
    'Test user preparation completed successfully.'
);
