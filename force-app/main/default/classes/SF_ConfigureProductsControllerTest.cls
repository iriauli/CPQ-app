/*
 * ============================================
 * @apexClassName: SF_ConfigureProductsControllerTest.cls
 * @description: Apex Configure Products Controller Test Class
 * @author: Irakli Iriauli
 * @dateCreated: 08/07/2022
 * @lastChange: 08/07/2022 by Irakli Iriauli
 * ============================================
*/
@isTest
public with sharing class SF_ConfigureProductsControllerTest {
    
    /*
     * @author: Irakli Iriauli
     * @description: Data For Testing
     */
    @TestSetup
    static void makeData(){
        Account testAccount = new Account(
            Name = 'Jason',
            Account_Location__c = 'United States',
            CurrencyIsoCode = 'USD'
        );

        insert testAccount;

        Opportunity testOpportunity = new Opportunity(
            Name = 'TestOpportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = System.today().addDays(7),
            CurrencyIsoCode = 'USD'
        );

        insert testOpportunity; 

        Contact testContact = new Contact(
            Salutation = 'Mr.',
            Primary__c = true,
            LastName = 'TestContact',
            AccountId = testAccount.Id,
            CurrencyIsoCode = 'USD'
        );

        insert testContact;

        Product2 testProduct = new Product2(
            Name = 'TestProduct',
            CurrencyIsoCode = 'USD',
            Is_Bundle__c = true
        );

        insert testProduct;

        SF_Price_List__c testPriceList = new SF_Price_List__c(
            Name = 'USD_Price_List',
            CurrencyIsoCode = 'USD'
        );

        insert testPriceList;

        SF_Price_List_Item__c testPriceListItem = new SF_Price_List_Item__c(
            Product__c = testProduct.Id,
            Price_List__c = testPriceList.Id,  
            Base_Price__c = 100
        );

        insert testPriceListItem;

        SF_Quote__c testQuote = new SF_Quote__c(
            Name = 'TestQuote',
            Status__c = 'Draft',
            Account__c = testAccount.Id,
            Opportunity__c = testOpportunity.Id,
            Contact__c = testContact.Id,
            Price_List__c = testPriceList.Id,
            Expiration_Date__c = System.today().addDays(7)
        );

        insert testQuote;

        SF_Quote_Line_Item__c testQliBundle = new SF_Quote_Line_Item__c(
            Name = 'testQliBundle',
            Product__c = testPriceListItem.Product__c,
            Price_List_Item__c = testPriceListItem.Id,
            Quote__c = testQuote.Id,
            // Total_Price__c = 100,
            // Subtotal__c = 100,
            Quantity__c = 1,
            Discount__c = 10,
            CurrencyIsoCode = 'USD', 
            Is_Bundle__c = true
        );

        insert testQliBundle;

        SF_Quote_Line_Item__c testQliOption = new SF_Quote_Line_Item__c(
            Name = 'testQliOption',
            Product__c = testPriceListItem.Product__c,
            Price_List_Item__c = testPriceListItem.Id,
            Quote__c = testQuote.Id,
            // Total_Price__c = 100,
            // Subtotal__c = 100,
            Quantity__c = 1,
            Discount__c = 10,
            CurrencyIsoCode = 'USD', 
            Is_Bundle__c = false
        );

        insert testQliOption;
    }

    /*
     * @author: Irakli Iriauli
     * @description: Get All Products Test
     */
    @isTest
    public static void test_getAllProducts() {
        List<Account> testAccount = [SELECT Id FROM Account WHERE Name = 'Jason'];
        List<Opportunity> testOpportunity = [SELECT Id FROM Opportunity WHERE AccountId =:testAccount[0].Id];
        List<SF_Quote__c> testQuote = [SELECT Id FROM SF_Quote__c WHERE Account__c =:testAccount[0].Id AND Opportunity__c =:testOpportunity[0].Id];

        System.assert((SF_ConfigureProductsController.getAllProducts(testQuote[0].Id)).size() > 0, 'Products Not Found');
    }

    /*
     * @author: Irakli Iriauli
     * @description: Get Quote Line Item Columns Test
     */
    @isTest
    public static void test_getQuoteLineItemColumns() {
        System.assert((SF_ConfigureProductsController.getQuoteLineItemColumns()).size() > 0, 'Columns Not Found');
    }

    /*
     * @author: Irakli Iriauli
     * @description: Clone Quote Line Items Test
     */
    @isTest
    public static void test_cloneQuoteLineItems() {
        List<Account> testAccount = [SELECT Id FROM Account WHERE Name = 'Jason'];
        List<Opportunity> testOpportunity = [SELECT Id FROM Opportunity WHERE AccountId =:testAccount[0].Id];
        List<SF_Quote__c> testQuote = [SELECT Id FROM SF_Quote__c WHERE Account__c =:testAccount[0].Id AND Opportunity__c =:testOpportunity[0].Id];

        List<SF_Quote_Line_Item__c> qlis = [SELECT Id, Name, Product__c, Price_List_Item__c, Quote__c, Quantity__c, CurrencyIsoCode, Is_Bundle__c FROM SF_Quote_Line_Item__c WHERE Quote__c =:testQuote[0].Id];
        SF_ConfigureProductsController.cloneQuoteLineItems(qlis, testQuote[0].Id);
        
        List<SF_Quote_Line_Item__c> allQlis = [SELECT Id FROM SF_Quote_Line_Item__c WHERE Quote__c =:testQuote[0].Id];
        System.assert(allQlis.size() > 3, 'Clone Failed');
    }
}
