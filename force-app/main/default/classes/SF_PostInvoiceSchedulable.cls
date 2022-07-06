global with sharing class SF_PostInvoiceSchedulable implements Schedulable {
     global void execute(SchedulableContext SC) { 
        database.executeBatch(new SF_PostInvoiceBatch());  
    }
}