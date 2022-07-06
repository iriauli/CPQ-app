@isTest
public with sharing class SF_CreateInvoiceBatchTest {
    @isTest
    public static void createInvoiceTest() {
        ID orderId = SF_DataFactory.createOrderAndOrderProducts(); 
        
        Test.startTest();
        ID batchprocessid = database.executeBatch(new SF_CreateInvoiceBatch()); 
        Test.stopTest();

        AsyncApexJob aaj = [SELECT Status FROM AsyncApexJob WHERE ID =: batchprocessid];
        System.assertEquals('Completed', aaj.Status, 'CreateInvoice Apex Job Failed');  

        SF_Invoice__c[] invoice = [SELECT Id FROM SF_Invoice__c WHERE Order__c =:orderId]; 
        System.assertEquals(false, invoice.isEmpty(), 'Invoice was not created');

        SF_Invoice_Line__c[] invoiceLineItem = [SELECT Id FROM SF_Invoice_Line__c WHERE Invoice__c =:invoice[0].Id];
        System.assertEquals(false, invoiceLineItem.isEmpty(), 'Invoice Line Item was not created');
    }
}