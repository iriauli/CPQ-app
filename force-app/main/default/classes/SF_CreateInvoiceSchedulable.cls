global with sharing class SF_CreateInvoiceSchedulable implements Schedulable {
     global void execute(SchedulableContext SC) { 
        database.executeBatch(new SF_CreateInvoiceBatch()); 
    }
}