public virtual with sharing class AgentforceSkillsExtractionService {

    @TestVisible
    private static final String INPUT_PARAM_CASE =
        'Input:Case';

    @TestVisible
    private static final String INPUT_PARAM_CASE_ATTACHMENT =
        'Input:CaseAttachment';

    @TestVisible
    private static final String INPUT_PARAM_SKILLS =
        'Input:Skills';

    @TestVisible
    private static final String APP_NAME_PROMPT_TEMPLATE_GENERATION_INVOCABLE =
        'PromptTemplateGenerationsInvocable';

    @TestVisible
    private static final String PROMPT_TEMPLATE_NAME =
        'CaseSkillRequirementsIdentification';

    @TestVisible
    private static AgentforceSkillsExtractionService instance;

    public static AgentforceSkillsExtractionService getInstance() {
        if (null == instance) {
            instance = new AgentforceSkillsExtractionService();
        }
        return instance;
    }

    public Set<String> getRequiredSkills(
        Case caseToAnalyze,
        ContentDocument caseAttachment
    ) {
        Set<String> requiredSkills = new Set<String>();

        if (null == caseToAnalyze || null == caseToAnalyze.Id) {
            return requiredSkills;
        }

        Set<String> allSkills = SkillSelector.getInstance().getSkills();

        if (null == allSkills || allSkills.isEmpty()) {
            return requiredSkills;
        }

        try {
            Map<String, ConnectApi.WrappedValue> inputParams =
                new Map<String, ConnectApi.WrappedValue>{
                    INPUT_PARAM_CASE =>
                        wrapRecord(caseToAnalyze.Id),
                    INPUT_PARAM_SKILLS =>
                        wrapValue(JSON.serialize(allSkills))
                };

            if (null != caseAttachment && null != caseAttachment.Id) {
                inputParams.put(
                    INPUT_PARAM_CASE_ATTACHMENT,
                    wrapRecord(caseAttachment.Id)
                );
            }

            ConnectApi.EinsteinPromptTemplateGenerationsInput input =
                new ConnectApi.EinsteinPromptTemplateGenerationsInput();
            input.inputParams = inputParams;
            input.isPreview = false;
            input.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
            input.additionalConfig.applicationName
                = APP_NAME_PROMPT_TEMPLATE_GENERATION_INVOCABLE;

            //Stub to allow further logic Apex unit testing w/o complex mocking.
            ConnectApi.EinsteinPromptTemplateGenerationsRepresentation response;
            String responseText;
            if (!Test.isRunningTest()) {
                response = ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(
                    PROMPT_TEMPLATE_NAME,
                    input
                );
                if (
                    null == response
                    || null == response.generations
                    || response.generations.isEmpty()
                    || String.isBlank(response.generations[0].text)
                ) {
                    return new Set<String>();
                }
                responseText = response.generations[0].text;
            } else {
                responseText = '{"skills":["Apex Programming","Debugging & Logs",'
                    + '"Apex Unit Testing","Performance & Limits"]}';
            }
            IdentifiedRequiredSkills identifiedSkills =
                (IdentifiedRequiredSkills) JSON.deserializeStrict(
                    responseText,
                    IdentifiedRequiredSkills.class
                );
            if (null == identifiedSkills || null == identifiedSkills.skills) {
                return new Set<String>();
            }
            requiredSkills = new Set<String>();
            for (String skill :identifiedSkills.skills) {
                if (String.isBlank(skill) || !allSkills.contains(skill)) {
                    continue;
                }
                requiredSkills.add(skill);
            }

            return requiredSkills;

        } catch (Exception e) {
            System.debug(
                'Failed to extract required skills. Error: ' +
                e.getMessage()
            );
            return new Set<String>();
        }
    }

    private static ConnectApi.WrappedValue wrapRecord(Id recordId) {
        return wrapValue(
            new Map<String, String>{'id' => String.valueOf(recordId)}
        );
    }

    private static ConnectApi.WrappedValue wrapValue(Object value) {
        ConnectApi.WrappedValue wrappedValue = new ConnectApi.WrappedValue();
        wrappedValue.value = value;
        return wrappedValue;
    }

    private class IdentifiedRequiredSkills {
        public List<String> skills;
    }
}