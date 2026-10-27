public with sharing class LexicographicCandidateScore {

    public Id userId { get; private set; }
    public Integer matchedSkillsCount { get; private set; }
    public Decimal averageMastery { get; private set; }

    public LexicographicCandidateScore(
        Id userId,
        Integer matchedSkillsCount,
        Decimal averageMastery
    ) {
        this.userId = userId;
        this.matchedSkillsCount = matchedSkillsCount;
        this.averageMastery = averageMastery;
    }
}