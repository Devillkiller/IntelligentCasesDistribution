trigger CaseTrigger on Case (after update) {
    CaseTriggerHandler.getInstance().run(Trigger.new, Trigger.oldMap);
}