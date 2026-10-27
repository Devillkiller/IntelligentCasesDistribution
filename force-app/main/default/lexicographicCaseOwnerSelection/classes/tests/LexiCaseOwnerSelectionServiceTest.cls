@isTest
private class LexiCaseOwnerSelectionServiceTest {

    private static final Id USER_ONE_ID =
        '005000000000001';

    private static final Id USER_TWO_ID =
        '005000000000002';

    @isTest
    static void testGetInstance() {
        Assert.isNull(
            LexicographicCaseOwnerSelectionService.instance,
            'No instance should be created until .getInstance() method is executed.'
        );

        LexicographicCaseOwnerSelectionService service =
            LexicographicCaseOwnerSelectionService.getInstance();

        Assert.isNotNull(
            LexicographicCaseOwnerSelectionService.instance,
            'Instance should be created after .getInstance() method is executed.'
        );

        Assert.areEqual(
            service,
            LexicographicCaseOwnerSelectionService.instance,
            'Returned instance should be the same as static one.'
        );
    }

    @isTest
    static void testSelectCaseOwner_nullRequiredSkills() {
        UserSelector userSelector = UserSelector.getInstance();

        userSelector.potentialUsersMemo =
            new List<User>{
                new User(Id = USER_ONE_ID)
            };

        userSelector.openCasesCountByUserIdMemo =
            new Map<Id, Integer>{
                USER_ONE_ID => 0
            };

        Id selectedUserId =
            LexicographicCaseOwnerSelectionService.getInstance().selectCaseOwner(
                null
            );

        Assert.isNull(
            selectedUserId,
            'Null required skills should not result in user selection.'
        );
    }

    @isTest
    static void testSelectCaseOwner_emptyRequiredSkills() {
        UserSelector userSelector = UserSelector.getInstance();

        userSelector.potentialUsersMemo =
            new List<User>{
                new User(Id = USER_ONE_ID)
            };

        userSelector.openCasesCountByUserIdMemo =
            new Map<Id, Integer>{
                USER_ONE_ID => 0
            };

        Id selectedUserId =
            LexicographicCaseOwnerSelectionService.getInstance().selectCaseOwner(
                new Set<String>()
            );

        Assert.isNull(
            selectedUserId,
            'Empty required skills should not result in user selection.'
        );
    }

    @isTest
    static void testSelectCaseOwner_noPotentialUsers() {
        UserSelector userSelector = UserSelector.getInstance();

        userSelector.potentialUsersMemo = new List<User>();

        Id selectedUserId =
            LexicographicCaseOwnerSelectionService.getInstance().selectCaseOwner(
                new Set<String>{
                    'Apex Programming'
                }
            );

        Assert.isNull(
            selectedUserId,
            'No potential users should result in no selected user.'
        );
    }

    @isTest
    static void testSelectCaseOwner_noEligibleUsers() {
        UserSelector userSelector = UserSelector.getInstance();

        userSelector.potentialUsersMemo =
            new List<User>{
                new User(Id = USER_ONE_ID),
                new User(Id = USER_TWO_ID)
            };

        userSelector.openCasesCountByUserIdMemo =
            new Map<Id, Integer>{
                USER_ONE_ID => 5,
                USER_TWO_ID => 5
            };

        Id selectedUserId =
            LexicographicCaseOwnerSelectionService.getInstance().selectCaseOwner(
                new Set<String>{
                    'Apex Programming'
                }
            );

        Assert.isNull(
            selectedUserId,
            'Users at maximum Case capacity should not be considered eligible.'
        );
    }

    @isTest
    static void testSelectCaseOwner_moreMatchedSkillsWins() {
        UserSelector userSelector =
            UserSelector.getInstance();

        userSelector.potentialUsersMemo =
            new List<User>{
                new User(Id = USER_ONE_ID),
                new User(Id = USER_TWO_ID)
            };

        userSelector.openCasesCountByUserIdMemo =
            new Map<Id, Integer>{
                USER_ONE_ID => 0,
                USER_TWO_ID => 0
            };

        UserSkillSelector userSkillSelector =
            UserSkillSelector.getInstance();

        userSkillSelector.userSkillsByUserIdMemo.put(
            USER_ONE_ID,
            new List<UserSkill__c>{
                new UserSkill__c(
                    UserId__c = USER_ONE_ID,
                    SkillName__c = 'Apex Programming',
                    Mastery__c = '5'
                ),
                new UserSkill__c(
                    UserId__c = USER_ONE_ID,
                    SkillName__c = 'Debugging & Logs',
                    Mastery__c = '5'
                )
            }
        );

        userSkillSelector.userSkillsByUserIdMemo.put(
            USER_TWO_ID,
            new List<UserSkill__c>{
                new UserSkill__c(
                    UserId__c = USER_TWO_ID,
                    SkillName__c = 'Apex Programming',
                    Mastery__c = '1'
                ),
                new UserSkill__c(
                    UserId__c = USER_TWO_ID,
                    SkillName__c = 'Debugging & Logs',
                    Mastery__c = '1'
                ),
                new UserSkill__c(
                    UserId__c = USER_TWO_ID,
                    SkillName__c = 'Flow Automation',
                    Mastery__c = '1'
                )
            }
        );

        Id selectedUserId =
            LexicographicCaseOwnerSelectionService.getInstance().selectCaseOwner(
                new Set<String>{
                    'Apex Programming',
                    'Debugging & Logs',
                    'Flow Automation'
                }
            );

        Assert.areEqual(
            USER_TWO_ID,
            selectedUserId,
            'User with more matched skills should be selected regardless of '
                + 'lower average mastery.'
        );
    }

    @isTest
    static void testSelectCaseOwner_higherAverageMasteryWins() {
        UserSelector userSelector =
            UserSelector.getInstance();

        userSelector.potentialUsersMemo =
            new List<User>{
                new User(Id = USER_ONE_ID),
                new User(Id = USER_TWO_ID)
            };

        userSelector.openCasesCountByUserIdMemo =
            new Map<Id, Integer>{
                USER_ONE_ID => 0,
                USER_TWO_ID => 0
            };

        UserSkillSelector userSkillSelector = UserSkillSelector.getInstance();

        userSkillSelector.userSkillsByUserIdMemo.put(
            USER_ONE_ID,
            new List<UserSkill__c>{
                new UserSkill__c(
                    UserId__c = USER_ONE_ID,
                    SkillName__c = 'Apex Programming',
                    Mastery__c = '5'
                ),
                new UserSkill__c(
                    UserId__c = USER_ONE_ID,
                    SkillName__c = 'Debugging & Logs',
                    Mastery__c = '4'
                )
            }
        );

        userSkillSelector.userSkillsByUserIdMemo.put(
            USER_TWO_ID,
            new List<UserSkill__c>{
                new UserSkill__c(
                    UserId__c = USER_TWO_ID,
                    SkillName__c = 'Apex Programming',
                    Mastery__c = '2'
                ),
                new UserSkill__c(
                    UserId__c = USER_TWO_ID,
                    SkillName__c = 'Debugging & Logs',
                    Mastery__c = '2'
                )
            }
        );

        Id selectedUserId =
            LexicographicCaseOwnerSelectionService.getInstance().selectCaseOwner(
                new Set<String>{
                    'Apex Programming',
                    'Debugging & Logs'
                }
            );

        Assert.areEqual(
            USER_ONE_ID,
            selectedUserId,
            'User with higher average mastery should be selected when matched skill '
                + 'count is equal.'
        );
    }

    @isTest
    static void testSelectCaseOwner_equalScoresKeepFirstUser() {
        UserSelector userSelector =
            UserSelector.getInstance();

        userSelector.potentialUsersMemo =
            new List<User>{
                new User(Id = USER_ONE_ID),
                new User(Id = USER_TWO_ID)
            };

        userSelector.openCasesCountByUserIdMemo =
            new Map<Id, Integer>{
                USER_ONE_ID => 0,
                USER_TWO_ID => 0
            };

        UserSkillSelector userSkillSelector = UserSkillSelector.getInstance();

        userSkillSelector.userSkillsByUserIdMemo.put(
            USER_ONE_ID,
            new List<UserSkill__c>{
                new UserSkill__c(
                    UserId__c = USER_ONE_ID,
                    SkillName__c = 'Apex Programming',
                    Mastery__c = '3'
                )
            }
        );

        userSkillSelector.userSkillsByUserIdMemo.put(
            USER_TWO_ID,
            new List<UserSkill__c>{
                new UserSkill__c(
                    UserId__c = USER_TWO_ID,
                    SkillName__c = 'Apex Programming',
                    Mastery__c = '3'
                )
            }
        );

        Id selectedUserId =
            LexicographicCaseOwnerSelectionService.getInstance().selectCaseOwner(
                new Set<String>{
                    'Apex Programming'
                }
            );

        Assert.areEqual(
            USER_ONE_ID,
            selectedUserId,
            'First user should remain selected when candidate scores are equal.'
        );
    }

    @isTest
    static void testSelectCaseOwner_noMatchedSkillsKeepsFirstUser() {
        UserSelector userSelector =
            UserSelector.getInstance();

        userSelector.potentialUsersMemo =
            new List<User>{
                new User(Id = USER_ONE_ID),
                new User(Id = USER_TWO_ID)
            };

        userSelector.openCasesCountByUserIdMemo =
            new Map<Id, Integer>{
                USER_ONE_ID => 0,
                USER_TWO_ID => 0
            };

        UserSkillSelector userSkillSelector =
            UserSkillSelector.getInstance();

        userSkillSelector.userSkillsByUserIdMemo.put(
            USER_ONE_ID,
            new List<UserSkill__c>()
        );

        userSkillSelector.userSkillsByUserIdMemo.put(
            USER_TWO_ID,
            new List<UserSkill__c>()
        );

        Id selectedUserId =
            LexicographicCaseOwnerSelectionService.getInstance().selectCaseOwner(
                new Set<String>{
                    'Apex Programming'
                }
            );

        Assert.areEqual(
            USER_ONE_ID,
            selectedUserId,
            'First eligible user should remain selected when all candidates have '
                + 'equal zero scores.'
        );
    }

    @isTest
    static void testSelectCaseOwner_userAtMaximumCapacityIsExcluded() {
        UserSelector userSelector = UserSelector.getInstance();

        userSelector.potentialUsersMemo =
            new List<User>{
                new User(Id = USER_ONE_ID),
                new User(Id = USER_TWO_ID)
            };

        userSelector.openCasesCountByUserIdMemo =
            new Map<Id, Integer>{
                USER_ONE_ID => 5,
                USER_TWO_ID => 0
            };

        UserSkillSelector userSkillSelector = UserSkillSelector.getInstance();

        userSkillSelector.userSkillsByUserIdMemo.put(
            USER_ONE_ID,
            new List<UserSkill__c>{
                new UserSkill__c(
                    UserId__c = USER_ONE_ID,
                    SkillName__c = 'Apex Programming',
                    Mastery__c = '5'
                )
            }
        );

        userSkillSelector.userSkillsByUserIdMemo.put(
            USER_TWO_ID,
            new List<UserSkill__c>{
                new UserSkill__c(
                    UserId__c = USER_TWO_ID,
                    SkillName__c = 'Apex Programming',
                    Mastery__c = '1'
                )
            }
        );

        Id selectedUserId =
            LexicographicCaseOwnerSelectionService.getInstance().selectCaseOwner(
                new Set<String>{
                    'Apex Programming'
                }
            );

        Assert.areEqual(
            USER_TWO_ID,
            selectedUserId,
            'User at maximum Case capacity should be excluded even when having '
                + 'a better score.'
        );
    }

    @isTest
    static void testSelectCaseOwner_pendingAssignmentIsTakenIntoAccount() {
        UserSelector userSelector =
            UserSelector.getInstance();

        userSelector.potentialUsersMemo =
            new List<User>{
                new User(Id = USER_ONE_ID),
                new User(Id = USER_TWO_ID)
            };

        userSelector.openCasesCountByUserIdMemo =
            new Map<Id, Integer>{
                USER_ONE_ID => 4,
                USER_TWO_ID => 0
            };

        UserSkillSelector userSkillSelector =
            UserSkillSelector.getInstance();

        userSkillSelector.userSkillsByUserIdMemo.put(
            USER_ONE_ID,
            new List<UserSkill__c>{
                new UserSkill__c(
                    UserId__c = USER_ONE_ID,
                    SkillName__c = 'Apex Programming',
                    Mastery__c = '5'
                ),
                new UserSkill__c(
                    UserId__c = USER_ONE_ID,
                    SkillName__c = 'Debugging & Logs',
                    Mastery__c = '5'
                )
            }
        );

        userSkillSelector.userSkillsByUserIdMemo.put(
            USER_TWO_ID,
            new List<UserSkill__c>{
                new UserSkill__c(
                    UserId__c = USER_TWO_ID,
                    SkillName__c = 'Apex Programming',
                    Mastery__c = '1'
                )
            }
        );

        LexicographicCaseOwnerSelectionService service =
            LexicographicCaseOwnerSelectionService.getInstance();

        Id firstSelectedUserId = service.selectCaseOwner(
            new Set<String>{
                'Apex Programming',
                'Debugging & Logs'
            }
        );

        Id secondSelectedUserId = service.selectCaseOwner(
            new Set<String>{
                'Apex Programming',
                'Debugging & Logs'
            }
        );

        Assert.areEqual(
            USER_ONE_ID,
            firstSelectedUserId,
            'User with four open Cases should still be eligible for one additional '
                + 'assignment.'
        );

        Assert.areEqual(
            USER_TWO_ID,
            secondSelectedUserId,
            'User should become ineligible after pending assignment brings effective '
                + 'Case count to the maximum.'
        );

        Assert.areEqual(
            1,
            service.pendingAssignmentsByUserId.get(
                USER_ONE_ID
            ),
            'First user should have one pending assignment registered.'
        );

        Assert.areEqual(
            1,
            service.pendingAssignmentsByUserId.get(
                USER_TWO_ID
            ),
            'Second user should have one pending assignment registered.'
        );
    }

    @isTest
    static void testSelectCaseOwner_multiplePendingAssignmentsUntilCapacityReached() {
        UserSelector userSelector = UserSelector.getInstance();

        userSelector.potentialUsersMemo =
            new List<User>{
                new User(Id = USER_ONE_ID),
                new User(Id = USER_TWO_ID)
            };

        userSelector.openCasesCountByUserIdMemo =
            new Map<Id, Integer>{
                USER_ONE_ID => 3,
                USER_TWO_ID => 0
            };

        UserSkillSelector userSkillSelector = UserSkillSelector.getInstance();

        userSkillSelector.userSkillsByUserIdMemo.put(
            USER_ONE_ID,
            new List<UserSkill__c>{
                new UserSkill__c(
                    UserId__c = USER_ONE_ID,
                    SkillName__c = 'Apex Programming',
                    Mastery__c = '5'
                )
            }
        );

        userSkillSelector.userSkillsByUserIdMemo.put(
            USER_TWO_ID,
            new List<UserSkill__c>{
                new UserSkill__c(
                    UserId__c = USER_TWO_ID,
                    SkillName__c = 'Apex Programming',
                    Mastery__c = '1'
                )
            }
        );

        LexicographicCaseOwnerSelectionService service =
            LexicographicCaseOwnerSelectionService.getInstance();

        Id firstSelectedUserId = service.selectCaseOwner(
            new Set<String>{
                'Apex Programming'
            }
        );

        Id secondSelectedUserId = service.selectCaseOwner(
            new Set<String>{
                'Apex Programming'
            }
        );

        Id thirdSelectedUserId = service.selectCaseOwner(
            new Set<String>{
                'Apex Programming'
            }
        );

        Assert.areEqual(
            USER_ONE_ID,
            firstSelectedUserId,
            'User with three open Cases should be eligible for the first assignment.'
        );

        Assert.areEqual(
            USER_ONE_ID,
            secondSelectedUserId,
            'User should remain eligible while effective Case count is below the maximum.'
        );

        Assert.areEqual(
            USER_TWO_ID,
            thirdSelectedUserId,
            'User should be excluded after effective Case count reaches the maximum.'
        );

        Assert.areEqual(
            2,
            service.pendingAssignmentsByUserId.get(
                USER_ONE_ID
            ),
            'Two pending assignments should be registered for the first user.'
        );

        Assert.areEqual(
            1,
            service.pendingAssignmentsByUserId.get(
                USER_TWO_ID
            ),
            'Third assignment should be registered for the second user.'
        );
    }
}