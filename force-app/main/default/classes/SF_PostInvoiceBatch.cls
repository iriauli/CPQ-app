public with sharing class SF_PostInvoiceBatch implements Database.Batchable<sObject>{

    public Database.querylocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([
             SELECT Invoice_Posted_Date__c,Status__c
             FROM SF_Invoice__c
             WHERE Status__c = 'Draft'
             AND Invoice_Date__c =:System.today() + 1
        ]); 
    }

    public void execute(Database.BatchableContext BC, List<SF_Invoice__c> scope){
        for(SF_Invoice__c i : scope) {
            i.Invoice_Posted_Date__c = System.today();
            i.Status__c = 'Posted';
        }
        update scope;
    }

    public void finish(Database.BatchableContext BC){}
}