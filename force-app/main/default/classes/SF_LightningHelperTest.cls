@isTest
public with sharing class SF_LightningHelperTest {
    @TestSetup
    static void makeData(){
        SF_Price_List__c priceList = new SF_Price_List__c(
            Active__c = true,
            CurrencyIsoCode = 'USD'
        ); 
        insert priceList;

        Account acc = new Account(Name = 'test');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'test',
            Price_List__c = priceList.Id,
            StageName = 'prospecting',
            CloseDate = System.today() + 5, 
            CurrencyIsoCode = 'USD',
            AccountId = acc.Id
        );
        insert opp;

        Product2 product = new Product2(
            Name = 'test',
            Description__c = 'test',
            CurrencyIsoCode = 'USD'
        );
        insert product; 

        SF_Price_List_Item__c pli = new SF_Price_List_Item__c(
            Price_List__c = priceList.Id,
            Product__c = product.Id,
            Base_Price__c = 250,
            Active__c = true
        );
        insert pli;
        
        SF_Quote__c quote = new SF_Quote__c( 
            Opportunity__c = opp.Id,
            Price_List__c = priceList.Id
        );
        insert quote;

        SF_Quote_Line_Item__c qli = new SF_Quote_Line_Item__c( 
            Quote__c = quote.Id,
            Price_List_Item__c = pli.Id, 
            Product__c = pli.Product__c
        );
        insert qli;
    }

    @isTest
    public static void cloneQuoteWithOutQlisTest() {
        SF_Quote__c ogQuote = [SELECT Id FROM SF_Quote__c LIMIT 1];
        ID recordId = SF_LightningHelper.cloneQuote(ogQuote.Id,false);

        System.assertNotEquals(null,recordId,'Cloning quote failed'); 
    }

    @isTest
    public static void cloneQuoteWithtQlisTest() {
        SF_Quote__c ogQuote = [SELECT Id FROM SF_Quote__c LIMIT 1];
        ID recordId = SF_LightningHelper.cloneQuote(ogQuote.Id,true);
        SF_Quote_Line_Item__c cloneQli = [SELECT Id FROM SF_Quote_Line_Item__c WHERE Quote__c =:recordId]; 
        
        System.assertNotEquals(null,recordId,'Cloning quote failed');
        System.assertNotEquals(null,cloneQli,'Cloning quote line items failed');
    }
}