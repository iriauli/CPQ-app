@isTest
public with sharing class SF_CreateOrderAndOrderProductsTest {
    @TestSetup
    static void makeData(){
        SF_DataFactory.genDataForTesting();
    }
    
    @isTest
    public static void executeTest() {
        SF_Quote__c quote = [SELECT Status__c FROM SF_Quote__c LIMIT 1];

        Test.startTest();
        quote.Status__c = 'Accepted';
        update quote;
        Test.stopTest();

        SF_Order__c order = [SELECT Id,Active__c FROM SF_Order__c LIMIT 1];
        SF_Order_Product__c orderProduct = [SELECT Status__c FROM SF_Order_Product__c WHERE Order__c =:order.Id LIMIT 1];

        System.assertEquals(null, order, 'Order was not created');
        System.assertEquals(false, order.Active__c, 'Order was not activated');

        System.assertEquals(null, orderProduct, 'Order Product was not created');
        System.assertEquals('Draft', orderProduct.Status__c, 'Order Product was not activated');
    } 
}