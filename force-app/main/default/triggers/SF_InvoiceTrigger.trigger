trigger SF_InvoiceTrigger on SF_Invoice__c (after insert) {
    if(Trigger.isAfter && Trigger.isInsert) {
        SF_InvoiceHelper.addNumberOfInvoicesOnOrder(Trigger.new);
    }
}