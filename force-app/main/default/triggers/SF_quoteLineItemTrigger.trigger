trigger SF_quoteLineItemTrigger on SF_Quote_Line_Item__c (before insert) { 
    if(Trigger.isBefore && Trigger.isInsert) {
        SF_quoteLineItemTriggerHelper.setValues(Trigger.new);
    }
}