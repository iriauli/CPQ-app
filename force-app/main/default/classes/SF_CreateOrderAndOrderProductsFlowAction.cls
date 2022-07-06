public with sharing class SF_CreateOrderAndOrderProductsFlowAction {
    @InvocableMethod
    public static void execute (List<ID> quoteIds) {
        SF_Quote__c[] quotes = [
            SELECT Id,
            Name,
            Opportunity__c,
            Primary__c,
            Price_List__c,
            Account__c,
            Contact__c,
            Status__c,
            NO_Line_Items__c,
            Billing_Postal_Code__c,
            Billing_State__c,
            Billing_Street__c,
            Shipping_Country__c,
            Billing_Country__c,
            Shipping_Postal_Code__c, 
            Total_Price__c,
            CurrencyIsoCode
            FROM SF_Quote__c
            WHERE Id IN :quoteIds
        ];
        SF_Quote_Line_Item__c[] qlis = [
            SELECT Id,
            Name,
            Unit_Price__c,
            Quote__c,
            Price_List_Item__r.Product__c,
            Product__c,
            Quantity__c, 
            Subtotal__c, 
            Total_Price__c ,
            CurrencyIsoCode  
            FROM SF_Quote_Line_Item__c 
            WHERE Quote__c IN :quoteIds
        ]; 

        if(qlis.isEmpty()) return;
         
        Map<ID,SF_Order__c> orders = new Map<ID,SF_Order__c>(); 
        List<SF_Order_Product__c> orderProducts = new List<SF_Order_Product__c>();

        for(SF_Quote__c q : quotes) {
            SF_Order__c order = new SF_Order__c( 
                Activated_Date__c = System.today(),  
                Active__c = true, 
                Shipping_Country__c = q.Shipping_Country__c,
                Shipping_Postal_Code__c = q.Shipping_Postal_Code__c,
                Billing_Street__c = q.Billing_Street__c,
                Billing_State__c = q.Billing_State__c,
                Billing_Country__c = q.Billing_Country__c,
                Billing_Postal_Code__c = q.Billing_Postal_Code__c,
                Order_Start_Date__c = System.today(),
                Order_End_Date__c = System.today() + 30,
                Opportunity__c = q.Opportunity__c,
                Account__c = q.Account__c,
                Contact__c = q.Contact__c,
                Attribute__c = '',
                Order_Amount__c = q.Total_Price__c,	
                Number_of_Order_Products__c = q.NO_Line_Items__c,
                Quote__c = q.Id,
                CurrencyIsoCode = q.CurrencyIsoCode
            );
            orders.put(q.Id, order); 
        }
        insert orders.values(); 

        for(SF_Quote_Line_Item__c qli : qlis) {
            SF_Order_Product__c orderProduct = new SF_Order_Product__c(
                Name = qli.Name,
                Status__c = 'Activated',
                Unit_Price__c = qli.Unit_Price__c,
                Start_Date__c = System.today(),
                End_Date__c = System.today() + 30,
                Total_Price__c = qli.Total_Price__c,
                Quote_Line_Item__c = qli.Id,
                Order__c = orders.get(qli.Quote__c).Id,  
                Product__c = qli.Product__c, 
                Quantity__c = qli.Quantity__c,
                Available_Quantity__c = qli.Quantity__c,
                CurrencyIsoCode = qli.CurrencyIsoCode 
            );
            orderProducts.add(orderProduct);
        }
        insert orderProducts;
    } 
}