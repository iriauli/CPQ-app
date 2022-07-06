/**
 * Quote Line Item creation helper class
 * @author Sandro
 */
public with sharing class SF_createQuoteLineItems {
    public static void create(SF_Quote__c[] quotes) {
        Map<ID, String> priceListMap = new Map<ID, String>();

        SF_Quote__c[] quoteList = [SELECT Id,Price_List__c,Opportunity__r.CurrencyIsoCode FROM SF_Quote__c WHERE Id IN :quotes];

        for(SF_Quote__c quote : quoteList) { 
            priceListMap.put(quote.Price_List__c, quote.Opportunity__r.CurrencyIsoCode);
        }

        Map<ID, List<SF_Price_List_Item__c>> priceListItemMap = new Map<ID, List<SF_Price_List_Item__c>>(); 
        for(SF_Price_List_Item__c pli : [
            SELECT Id,Price_List__c,Product__c,Product__r.Name,Product__r.Description__c,Base_Price__c,Active__c 
            FROM SF_Price_List_Item__c 
            WHERE Price_List__c IN :priceListMap.keySet()
            AND active__c = TRUE 
            AND currencyIsoCode IN :priceListMap.values() 
        ]) { 
            List<SF_Price_List_Item__c> plis = priceListItemMap.get(pli.Price_List__c); 
            if(plis == NULL) {
                List<SF_Price_List_Item__c> newPlis = new List<SF_Price_List_Item__c>();
                newplis.add(pli); 
                priceListItemMap.put(pli.Price_List__c, newPlis); 
            } else {   
                plis.add(pli);
                priceListItemMap.put(pli.Price_List__c, plis); 
            }
        }
        
        SF_Quote_Line_Item__c[] qliList = new List<SF_Quote_Line_Item__c>(); 
        for(SF_Quote__c quote : quoteList) {   
            for(SF_Price_List_Item__c pli : priceListItemMap.get(quote.Price_List__c)) {
                SF_Quote_Line_Item__c qli = new SF_Quote_Line_Item__c( 
                    Name = pli.Product__r.Name,
                    Unit_Price__c = pli.Base_Price__c,
                    Quote__c = quote.Id,
                    Price_List_Item__c = pli.Id, 
                    Product__c = pli.Product__c, 
                    Discount__c = 0,
                    Line_Item_Description__c = pli.Product__r.Description__c,
                    Quantity__c = 1
                );
                qliList.add(qli);
            } 
        }
        insert qliList;
    } 
}