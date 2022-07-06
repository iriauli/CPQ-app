/**
 * LWC Utility Class
 * @author Sandro
 */
public with sharing class SF_LightningHelper { 
    @AuraEnabled
    public static String createQuote( 
        String accountId,String name,String opportunityId,String priceListId,Date expirationDate,Boolean primary,String status
        ){ 
        Contact[] primaryContact = [SELECT Id FROM Contact WHERE AccountId = :accountId AND Primary__c = true];
    
        SF_Quote__c quote = new SF_Quote__c(); 
        quote.Name = name; 
        quote.Account__c = accountId;
        quote.Contact__c = primaryContact.isEmpty() ? null : primaryContact[0].Id;
        quote.Opportunity__c = opportunityId;
        quote.Price_List__c = priceListId;
        quote.Primary__c = primary; 
        quote.Status__c = status; 
        quote.Expiration_Date__c = expirationDate != NULL ? expirationDate : System.today() + 7;

        try {
            insert quote;
            return quote.Id;
        } catch (Exception e) { 
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled 
    public static string cloneQuote(ID quoteId,Boolean wihtQuoteLineItems){ 
        Clone_Quote_Fields_Mapping__mdt cqfm = [SELECT Quote_Fields__c,Line_Item_Fields__c FROM Clone_Quote_Fields_Mapping__mdt];

        String qry = 'SELECT ' + cqfm.Quote_Fields__c + ' FROM SF_Quote__c WHERE Id =:quoteId'; 
        SF_Quote__c ogQuote = Database.query(qry); 
        SF_Quote__c cloneQuote = ogQuote.clone(false, true, false, false); 
        insert cloneQuote;  

        if(!wihtQuoteLineItems) return cloneQuote.Id; 

        qry = 'SELECT ' + cqfm.Line_Item_Fields__c + ' FROM SF_Quote_Line_Item__c WHERE Quote__c =:quoteId'; 
        SF_Quote_Line_Item__c[] ogQlis = Database.query(qry); 
        if(!ogQlis.isEmpty()) {
            SF_Quote_Line_Item__c[] cloneQlis = ogQlis.deepClone(false,false,false); 
            for(SF_Quote_Line_Item__c qli : cloneQlis) {
                qli.Quote__c = cloneQuote.Id; 
            }  
            insert cloneQlis;
        }

        return cloneQuote.Id; 
    }

    @AuraEnabled(cacheable=true)
    public static SF_QuantityRange__c[] getQuantityRangesByPLIsId(ID pliId){
        return [
            SELECT Id,Price__c,Quantity_From__c,Quantity_To__c,CurrencyIsoCode FROM SF_QuantityRange__c WHERE Price_List_Item__c =:pliId ORDER BY Quantity_From__c
        ];
    }

    @AuraEnabled
    public static void upsertQuantityRanges(SF_QuantityRange__c[] qrs, ID pliId){
        try {
            Map<ID,SF_QuantityRange__c> qrsNewMap = new Map<ID,SF_QuantityRange__c>();
            qrsNewMap.putAll(qrs);
            SF_QuantityRange__c[] qrsOld = [SELECT Id,Price__c,Quantity_From__c,Quantity_To__c,Price_List_Item__c FROM SF_QuantityRange__c WHERE Price_List_Item__c =: pliId];
            System.debug(qrsOld); 
            for(Integer i = 0; i < qrsOld.size(); i++) {
                if(qrsNewMap.containsKey(qrsOld[i].Id)) {
                    qrsOld.remove(i);
                    i--;
                }
            } 
            if(!qrsOld.isEmpty()) {
                delete qrsOld;
            }
            upsert qrs; 
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}