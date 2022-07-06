@isTest
public with sharing class SF_PostInvoiceBatchTest {
    @isTest  
    public static void postInvoiceBatchTest() { 
        Account acc = new Account(Name = 'test'); 
        insert acc;

        SF_Invoice__c invoice = new SF_Invoice__c(
            Invoice_Posted_Date__c = System.today() + 1,
            Status__c = 'Draft',
            Account__c = acc.Id,
            Invoice_Date__c = System.today() + 1
        );
        insert invoice;
        
        Test.startTest();
        ID batchprocessid = database.executeBatch(new SF_PostInvoiceBatch()); 
        Test.stopTest(); 

        AsyncApexJob aaj = [SELECT Status FROM AsyncApexJob WHERE ID =: batchprocessid]; 
        System.assertEquals('Completed', aaj.Status, 'PostInvoice Apex Job Failed');  
        
        SF_Invoice__c postedInvoice = [SELECT Invoice_Posted_Date__c,Status__c FROM SF_Invoice__c WHERE Id =:invoice.Id];
        System.assertEquals('Posted', postedInvoice.Status__c, 'Invoice was not posted');   
    }
}