/**
 * batch class for creating invoice records for orders which do not have invoice
 * @author Sandro 
 */
public with sharing class SF_CreateInvoiceBatch implements Database.Batchable<sObject>{

    public Database.querylocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([
             SELECT Id,Name, CurrencyIsoCode, Opportunity__c, Account__c, Order_Amount__c, NO_Invoices__c 
             FROM SF_Order__c
             WHERE Active__c = true  
             AND NO_Invoices__c = 0
        ]);  
    }

    public void execute(Database.BatchableContext BC, List<SF_Order__c> scope){
        Map<ID,SF_Invoice__c> invoices = new Map<ID,SF_Invoice__c>();
        for(SF_Order__c order : scope) {
            SF_Invoice__c invoice = new SF_Invoice__c(
                CurrencyIsoCode = order.CurrencyIsoCode,
                Order__c = order.Id,
                Account__c = order.Account__c,
                Payments__c = 0,
                Invoice_Date__c = System.today() + 2,  
                Balance__c = order.Order_Amount__c,
                Allocations__c = 0,
                Status__c = 'Draft'
            );
            invoices.put(order.Id,invoice);
        }
        if(!invoices.isEmpty()) {
            insert invoices.values();
        }

        SF_Invoice_Line__c[] invoiceLines = new List<SF_Invoice_Line__c>();
        for(SF_Order_Product__c op : [SELECT Id,Name,Order__c,Total_Price__c,CurrencyIsoCode,Product__c FROM SF_Order_Product__c WHERE Order__c IN :scope]) {
            SF_Invoice_Line__c il = new SF_Invoice_Line__c( 
                CurrencyIsoCode = op.CurrencyIsoCode, 
                Invoice__c = invoices.get(op.Order__c).Id,
                Status__c = 'Draft', 
                Allocations__c = 0, 
                Start_Date__c = System.today(),
                End_Date__c = System.today() + 7,
                Invoice_Amount__c = op.Total_Price__c,
                Product__c = op.Product__c,
                Order_Product__c = op.Id
            ); 
            invoiceLines.add(il); 
        }
        if(!invoiceLines.isEmpty()) insert invoiceLines;  
    }

    public void finish(Database.BatchableContext BC){}
}