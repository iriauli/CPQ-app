/**
 * QUote Line Item Trigger helper Class
 * @author Sandro 
 */
public with sharing class SF_quoteLineItemTriggerHelper {
    public static void setValues(List<SF_Quote_Line_Item__c> qlis) {    
        Set<Id> productIds = new Set<Id>();
        Set<Id> pliIds = new Set<Id>();
            
        for(SF_Quote_Line_Item__c qli : qlis) {
            productIds.add(qli.Product__c);
            pliIds.add(qli.Price_List_Item__c);
        }  
            
        Map<ID, Product2> products = new Map<ID, Product2>([
            SELECT Id, Name, Description__c, Is_Bundle__c 
            FROM Product2 
            WHERE Id IN :productIds
        ]);
        Map<ID, SF_Price_List_Item__c> plis = new Map<ID, SF_Price_List_Item__c>([
            SELECT Id, Base_Price__c 
            FROM SF_Price_List_Item__c 
            WHERE Id IN :pliIds
        ]);
            
        for(SF_Quote_Line_Item__c qli : qlis) { 
            Product2 product = products.get(qli.Product__c);
            qli.Line_Item_Description__c = product.Description__c;
            qli.Name = product.Name;
            // qli.Quantity__c = 1; davakomentare, xels mishlida.

            SF_Price_List_Item__c pli = plis.get(qli.Price_List_Item__c); 
            qli.List_Price__c = pli.Base_Price__c; 
			qli.Unit_Price__c = pli.Base_Price__c;
        }
    }
}