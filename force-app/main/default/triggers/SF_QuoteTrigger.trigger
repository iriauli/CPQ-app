/**
 * SF_Quote__c Trigger
 * @author Sandro 
 */ 
trigger SF_QuoteTrigger on SF_Quote__c (before insert,before update,before delete) {
    if(Trigger.isBefore) { 
        if(Trigger.isInsert) { 
            SF_QuoteTriggerHelper.insertFired = true;
            SF_QuoteTriggerHelper.validateQuotePrimarity(Trigger.new, Trigger.old, false, false);
        } else if(Trigger.isUpdate) {
            if(SF_QuoteTriggerHelper.insertFired) {
                SF_QuoteTriggerHelper.insertFired = false;
            } else if(SF_QuoteTriggerHelper.updateFired) {
                SF_QuoteTriggerHelper.updateFired = false;
            } else {
                SF_QuoteTriggerHelper.updateFired = true;
                SF_QuoteTriggerHelper.validateQuotePrimarity(Trigger.new, Trigger.old, true, false);
            }
        } else if(Trigger.isDelete) {
            SF_QuoteTriggerHelper.validateQuotePrimarity(Trigger.new, Trigger.old, false, true);
        }
    } 
}