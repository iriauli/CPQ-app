public with sharing class SF_InvoiceHelper {
    public static void addNumberOfInvoicesOnOrder(SF_Invoice__c[] invoices) {
        Map<ID,Integer> invoiceMap = new Map<ID,Integer>();
        for(SF_Invoice__c invoice : invoices) {
            if(invoiceMap.containsKey(invoice.Order__c)) {
                Integer count = invoiceMap.get(invoice.Order__c);  
                invoiceMap.put(invoice.Order__c, ++count);  
            } else { 
                invoiceMap.put(invoice.Order__c, 1);
            }
        }
        SF_Order__c[] orders = [SELECT NO_Invoices__c FROM SF_Order__c WHERE Id IN :invoiceMap.keySet()];
        for(SF_Order__c order : orders) { 
            order.NO_Invoices__c = invoiceMap.get(order.Id);
        }
        update orders;
    }
}