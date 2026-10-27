@isTest
private class SkillSelectorTest {

    @isTest
    static void testGetInstance() {
        Assert.isNull(
            SkillSelector.instance,
            'No instance should be created untill .getInstance() method is executed.'
        );
        SkillSelector selector = SkillSelector.getInstance();
        Assert.isNotNull(
            SkillSelector.instance,
            'Instance should be created after .getInstance() method is executed.'
        );
        Assert.areEqual(
            selector,
            SkillSelector.instance,
            'Returned instance should be the same as static one.'
        );
    }

    @isTest
    static void testGetSkills() {
        SkillSelector selector = SkillSelector.getInstance();
        Set<String> skills = selector.getSkills();
        Assert.isNotNull(
            skills,
            'Active skills should exist and be returned by .getSkills() method.'
        );
    }
}