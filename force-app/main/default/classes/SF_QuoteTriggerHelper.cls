/**
 * SF_Quote__c Trigger Helper Class
 * @author Sandro  
 */ 
public with sharing class SF_QuoteTriggerHelper {
    public static boolean insertFired = false;  
    public static boolean updateFired = false;   

    public static void validateQuotePrimarity(List<SF_Quote__c> newQuotes,List<SF_Quote__c> oldQuotes, Boolean isUpdate, Boolean isDelete) {
        if(isDelete) {
            for(SF_Quote__c quote : oldQuotes) {
                if(quote.Primary__c) {   
                    quote.addError(System.Label.auraDeleteMessage);  
                    return;
                } 
            } 
            return;
        }
        
        Set<ID> oppIds = new Set<ID>();
        for(SF_Quote__c quote : newQuotes) {
            oppIds.add(quote.Opportunity__c);
        }

        Map<ID,List<SF_Quote__c>> oppPrimaryQuotesMap = new Map<ID,List<SF_Quote__c>>();
        for(SF_Quote__c quote : [SELECT Opportunity__c FROM SF_Quote__c WHERE Primary__c = true AND Status__c != 'Accepted' AND Opportunity__c IN :oppIds]) { 
            if(oppPrimaryQuotesMap.containsKey(quote.Opportunity__c)) {
                List<SF_Quote__c> temp = oppPrimaryQuotesMap.get(quote.Opportunity__c);
                temp.add(quote); 
                oppPrimaryQuotesMap.put(quote.Opportunity__c, temp); 
            } else {
                oppPrimaryQuotesMap.put(quote.Opportunity__c, new List<SF_Quote__c>{quote});
            } 
        }

        if(isUpdate) {
            Map<ID,SF_Quote__c> newQuoteMap = new Map<ID,SF_Quote__c>();
            newQuoteMap.putAll(newQuotes);
            
            List<SF_Quote__c> records = new List<SF_Quote__c>();

            for(SF_Quote__c quote : oldQuotes) {
                if(quote.Primary__c && !newQuoteMap.get(quote.id).Primary__c) {  
                    newQuoteMap.get(quote.id).addError(System.Label.auraMessage); 
                } else if (!quote.Primary__c && newQuoteMap.get(quote.id).Primary__c) { 
                    if(oppPrimaryQuotesMap.containsKey(quote.Opportunity__c)) {
                        records = mapFields(oppPrimaryQuotesMap.get(quote.Opportunity__c), quote.Id);
                    }
                }
            }
            if(!records.isEmpty()) {
                update records; 
            }
        } else {
            List<SF_Quote__c> records = new List<SF_Quote__c>();
            for(SF_Quote__c quote : newQuotes) {
                if(quote.Primary__c) {
                   if(oppPrimaryQuotesMap.containsKey(quote.Opportunity__c)) {
                       records = mapFields(oppPrimaryQuotesMap.get(quote.Opportunity__c), quote.Id);
                   }
                } 
            }  
            if(!records.isEmpty()) {
                update records; 
            }
        }
    } 

    private static List<SF_Quote__c> mapFields(List<SF_Quote__c> primaryQuotes, ID quoteId) {
        List<SF_Quote__c> records = new List<SF_Quote__c>();
        for(SF_Quote__c quote : primaryQuotes) {
            if(quote.Id != quoteId) {   
                quote.Primary__c = false;
                records.add(quote);
            }
        }
        return records;
    }
}