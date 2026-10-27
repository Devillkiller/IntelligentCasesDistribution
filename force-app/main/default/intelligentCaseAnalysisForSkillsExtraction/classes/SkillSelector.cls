public inherited sharing class SkillSelector {
    @TestVisible
    private static SkillSelector instance;

    @TestVisible
    private Set<String> skills;

    public static SkillSelector getInstance() {
        if (null == instance) {
            instance = new SkillSelector();
        }
        return instance;
    }

    public Set<String> getSkills() {
        if (null != skills && !skills.isEmpty()) {
            return skills;
        }
        skills = new Set<String>();
        for (
            Schema.PicklistEntry entry 
                :UserSkill__c.SkillName__c.getDescribe().getPicklistValues()
            ) {
            if (entry.isActive()) {
                skills.add(entry.getValue());
            }
        }
        return skills;
    }
}