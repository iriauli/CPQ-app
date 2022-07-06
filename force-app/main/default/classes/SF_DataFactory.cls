public with sharing class SF_DataFactory {
    public static ID createOrderAndOrderProducts() {
        SF_Price_List__c priceList = new SF_Price_List__c(
            Active__c = true,
            CurrencyIsoCode = 'USD'
        );
        insert priceList;

        Account acc = new Account(Name = 'test'); 
        insert acc;

        Contact contact = new Contact(LastName='test',Primary__c=true,AccountId=acc.Id);
        insert contact; 

        Opportunity opp = new Opportunity(
            Name = 'test',
            Price_List__c = priceList.Id,
            StageName = 'prospecting',
            CloseDate = System.today() + 5,  
            CurrencyIsoCode = 'USD',
            AccountId = acc.Id,
            Billing_Country__c = 'test',
            Billing_Postal_Code__c = 'test',
            Billing_State__c = 'test',
            Billing_Street__c = 'test',
            Shipping_Country__c = 'test',
            Shipping_Postal_Code__c = 'test',
            Shipping_State__c = 'test',
            Shipping_Street__c = 'test'
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
            Name = 'test',
            Opportunity__c = opp.Id,
            Primary__c = true,
            Price_List__c = priceList.Id,
            Account__c = acc.Id,
            Contact__c = contact.Id,
            Status__c = 'Draft', 
            Expiration_Date__c = System.today() + 2
        );
        insert quote;

        SF_Quote_Line_Item__c qli = new SF_Quote_Line_Item__c(
            Name = 'test',
            Quote__c = quote.Id,
            Product__c = product.Id,
            Price_List_Item__c = pli.Id
        );
        insert qli;
        
        SF_Order__c order = new SF_Order__c(
            CurrencyIsoCode = 'USD',
            Opportunity__c = opp.Id,
            Account__c = acc.Id,
            Order_Amount__c = 123
        );  
        insert order;

        SF_Order_Product__c op = new SF_Order_Product__c(
            Name = 'test', 
            Order__c = order.Id,
            Total_Price__c = 123,
            CurrencyIsoCode = 'USD',
            Product__c = product.Id    
        );
        insert op;

        return order.Id; 
    }
}