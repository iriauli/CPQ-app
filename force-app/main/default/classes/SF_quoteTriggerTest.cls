/**
 * Quote Trigger Test Class
 * @author Sandro
 */
@isTest
public with sharing class SF_quoteTriggerTest {
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
    }

    /**
     * @author Sandro
     * Test - new primary quote should update existing primary quote on same opportunity to non-primary
     */
    @isTest
    public static void validateQuotePrimarityTestCaseOne() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        SF_Price_List__c priceList = [SELECT Id FROM SF_Price_List__c LIMIT 1];

        SF_Quote__c primaryQuote = new SF_Quote__c(
            Opportunity__c = opp.Id,
            Price_List__c = priceList.Id,
            Primary__c = true,
            Status__c = 'Draft'  
        );
        insert primaryQuote;

        SF_Quote__c newPrimaryQuote = new SF_Quote__c(
            Opportunity__c = opp.Id,
            Price_List__c = priceList.Id,
            Primary__c = true 
        );

        Test.startTest();
        insert newPrimaryQuote;
        Test.stopTest();

        SF_Quote__c result = [SELECT Primary__c FROM SF_Quote__c WHERE Status__c = 'Draft'];

        System.assertEquals(false, result.Primary__c);
    }
 
    /**
     * @author Sandro
     * Test - non-primary quote,s update to primary should also update already existing primary to non-primary
     */
    @isTest
    public static void validateQuotePrimarityTestCaseTwo() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        SF_Price_List__c priceList = [SELECT Id FROM SF_Price_List__c LIMIT 1];

        SF_Quote__c nonPrimaryQuote = new SF_Quote__c(
            Opportunity__c = opp.Id,
            Price_List__c = priceList.Id,
            Primary__c = false 
        );
        insert nonPrimaryQuote; 

        SF_Quote__c newPrimaryQuote = new SF_Quote__c(
            Opportunity__c = opp.Id,
            Price_List__c = priceList.Id,
            Primary__c = true,
            Status__c = 'Draft'  
        );
        insert newPrimaryQuote;

        nonPrimaryQuote.Primary__c = true;

        Test.startTest();
        update nonPrimaryQuote;
        Test.stopTest();

        SF_Quote__c result = [SELECT Primary__c FROM SF_Quote__c WHERE Status__c = 'Draft'];

        System.assertEquals(false, result.Primary__c);
    }
}