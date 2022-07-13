/*
 * ============================================
 * @apexClassName: SF_ConfigureProductsController.cls
 * @description: Apex class that includes Configured Products List (Quote Line Items, Products, etc.)
 * @author: Irakli Iriauli
 * @dateCreated: 27/05/2022
 * @lastChange: 06/07/2022 by Irakli Iriauli
 * ============================================
*/
public with sharing class SF_ConfigureProductsController {

    /*
     * @author: Irakli Iriauli
     * @description: Get Label Names By Field API Name
     */
    @AuraEnabled(cacheable=true)
    public static List<String> getQuoteLineItemColumns(){
        List<Quote_Line_Item_Config__mdt> fieldsFromMetadata = [SELECT Fields__c FROM Quote_Line_Item_Config__mdt];
        
        List<String> splitedFields = fieldsFromMetadata[0].Fields__c.split(',');

        Set<String> columns = new Set<String>();
        columns.addAll(splitedFields);
        
        List<String> columnList = new List<String>();
            for(String column : columns){

                String columnNames = (String)Schema.getGlobalDescribe().get('SF_Quote_Line_Item__c').getDescribe().fields.getMap().get(column).getDescribe().getLabel();

                if(columnNames != 'Currency Iso Code')
                    columnList.add(columnNames);
                }

        Cache.Org.put('local.QuoteLineItems.qliColumns', columnList);
        List<String> cachedColumns = (List<String>)Cache.Org.get('local.QuoteLineItems.qliColumns');

        return cachedColumns;
    }

    /*
     * @author: Irakli Iriauli
     * @description: Configure Quote Line Items
     */
    @AuraEnabled(cacheable=true)
    public static List<SF_Quote_Line_Item__c> getQuoteLineItems(Id quoteId) {
        List<Quote_Line_Item_Config__mdt> fieldsFromMetadata = [SELECT Fields__c FROM Quote_Line_Item_Config__mdt];

        List<String> fields = fieldsFromMetadata[0].Fields__c.split(',');
        String fieldString = string.join(fields,',');

        String dynamicQuery = 'SELECT Id, Quote_Line_Item__c, Is_Bundle__c, Product__c, Price_List_Item__c, ' + fieldString + ' FROM SF_Quote_Line_Item__c WHERE Quote__c =:quoteId ORDER BY Id ASC';
        List<SF_Quote_Line_Item__c> quoteLineItemList = Database.query(dynamicQuery);

        return quoteLineItemList;
    }

    /*
     * @author: Irakli Iriauli
     * @description: Get Products with Options
     */
    @AuraEnabled(cacheable=true)
    public static List<ProductWrapper> getAllProducts(Id quoteId) {
        List<SF_Quote__c> priceList = [SELECT Price_List__c FROM SF_Quote__c WHERE Id=:quoteId];
        
        // Get all plis of a particular price list/currency
        List<SF_Price_List_Item__c> plis = [SELECT Product__c, Base_Price__c, CurrencyIsoCode 
                                            FROM SF_Price_List_Item__c 
                                            	WHERE Price_List__c=:priceList[0].Price_List__c AND Active__c=true];
        
        // Do mapping productId vs. plis
        Map<ID, SF_Price_List_Item__c> pliMap = new Map<ID, SF_Price_List_Item__c>();
        for (SF_Price_List_Item__c pli : plis) {
            pliMap.put(pli.Product__c, pli);
        }
        
        // Get all products associated to the select plis
        List<Product2> products = [SELECT Id, Name, Optional__c, Product__c, Is_bundle__c, IsActive, CurrencyIsoCode FROM Product2 WHERE Id IN :pliMap.keySet() ORDER BY Name ];
        
        List<ProductWrapper> allProducts = new List<ProductWrapper>();
        for(Product2 pr : products){
            allProducts.add(new ProductWrapper(pr, pliMap.get(pr.Id)));
        }
        
        return allProducts;
    }
    
    public class ProductWrapper{
        @AuraEnabled public String Id { get; set; }
        @AuraEnabled public String productId { get; set; }
        @AuraEnabled public String productName { get; set; }
        @AuraEnabled public Decimal basePrice { get; set; }
        @AuraEnabled public Boolean isBundle { get; set; }
        @AuraEnabled public Boolean isOptional { get; set; }
        @AuraEnabled public String currencyIsoCode { get; set; }
        @AuraEnabled public String priceListItemId { get; set; }
        
        public ProductWrapper(Product2 pr, SF_Price_List_Item__c pli){
            this.Id = pr.Id;
            this.productId = pr.Product__c;
            this.productName = pr.Name;
            this.currencyIsoCode = pr.currencyIsoCode;
            this.isOptional = pr.Optional__c;
            this.isBundle = pr.Is_bundle__c;
            this.priceListItemId = pli.Id;
            if(pli != null){                
            	this.basePrice = pli.Base_Price__c;
            }
        }        
    }

    /*
     * @author: Irakli Iriauli
     * @description: Clone Quote Line Items
     */
    @AuraEnabled
    public static void cloneQuoteLineItems(Id qliId) {
        List<Quote_Line_Item_Config__mdt> fieldsFromMetadata = [SELECT Fields__c FROM Quote_Line_Item_Config__mdt];
        List<String> fields = fieldsFromMetadata[0].Fields__c.split(',');
        String fieldString = string.join(fields,',');

        String dynamicQueryForBundles = 'SELECT Id, Quote_Line_Item__c, Is_Bundle__c, Product__c, Price_List_Item__c, Quote__c, ' + fieldString + ' FROM SF_Quote_Line_Item__c WHERE Id =:qliId';
        List<SF_Quote_Line_Item__c> bundleItems = Database.query(dynamicQueryForBundles);

        List<SF_Quote_Line_Item__c> clonedBundleItems = new List<SF_Quote_Line_Item__c>();
        for(SF_Quote_Line_Item__c bundleItem : bundleItems) {
            SF_Quote_Line_Item__c cloneBundles = bundleItem.clone(false, true, false, false);
            clonedBundleItems.add(cloneBundles);
        }
    
        insert clonedBundleItems;

        String dynamicQueryForOptions = 'SELECT Id, Quote_Line_Item__c, Is_Bundle__c, Product__c, Price_List_Item__c, Quote__c, ' + fieldString + ' FROM SF_Quote_Line_Item__c WHERE Quote_Line_Item__c =:qliId';
        List<SF_Quote_Line_Item__c> optionItems = Database.query(dynamicQueryForOptions);

        List<SF_Quote_Line_Item__c> clonedOptionItems = new List<SF_Quote_Line_Item__c>();
        for(SF_Quote_Line_Item__c optionItem : optionItems){
            SF_Quote_Line_Item__c cloneOptions = optionItem.clone(false, true, true, true);
            cloneOptions.Quote_Line_Item__c = clonedBundleItems[0].Id;
            clonedOptionItems.add(cloneOptions);
        }

        insert clonedOptionItems;
    }

    /*
     * @author: Irakli Iriauli
     * @description: Create Quote Line Items
     */
    @AuraEnabled
    public static void createQuoteLineItems(List<productToQuoteLineItemWrapper> products, Id quoteId) {

        List<SF_Quote_Line_Item__c> quoteLineItemList = new List<SF_Quote_Line_Item__c>();
        
        for(productToQuoteLineItemWrapper pr : products) {
            SF_Quote_Line_Item__c newQuoteLineItem = new SF_Quote_Line_Item__c(
                Name = pr.name,
                Product__c = pr.Id,
                Price_List_Item__c = pr.pliId,
                Quote__c = quoteId,
                Total_Price__c = pr.totalPrice,
                Subtotal__c = pr.subtotal,
                Quantity__c = pr.quantity,
                CurrencyIsoCode = pr.currencyIsoCode,
                Discount__c = 10,
                Is_Bundle__c = pr.isBundle
            );
                quoteLineItemList.add(newQuoteLineItem);     
        }

    List<SF_Quote_Line_Item__c> bundleItems = new List<SF_Quote_Line_Item__c>();
    List<SF_Quote_Line_Item__c> childItems = new List<SF_Quote_Line_Item__c>();

            for(SF_Quote_Line_Item__c qli : quoteLineItemList) {
                if(qli.Is_Bundle__c) {
                    bundleItems.add(qli);
                } else {
                    childItems.add(qli);
                }
            }

            insert bundleItems;

            for(SF_Quote_Line_Item__c child : childItems) {
                child.Quote_Line_Item__c = bundleItems[0].Id;
            }

            insert childItems;
    }

    public class productToQuoteLineItemWrapper {
        @AuraEnabled public Id Id { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public Id pliId { get; set; }
        @AuraEnabled public Decimal quantity { get; set; }
        @AuraEnabled public Decimal totalPrice { get; set; }
        @AuraEnabled public Decimal subtotal { get; set; }
        @AuraEnabled public String currencyIsoCode { get; set; }
        @AuraEnabled public Boolean isBundle { get; set; }
    }

    /*
     * @author: Irakli Iriauli
     * @description: Update Quote Line Item Quantity
     */
    @AuraEnabled
    public static void updateQuoteLineItemQuantity(SF_Quote_Line_Item__c option) {
        SF_Quote_Line_Item__c quoteLineItem = new SF_Quote_Line_Item__c(
            Id = option.Id,
            Quantity__c = option.Quantity__c);
            update quoteLineItem;
    }

    /*
     * @author: Irakli Iriauli
     * @description: Compute Prices
     */
    @AuraEnabled
    public static void computePrices(Id pliId) {
        List<SF_Price_List_Item__c> plis = [SELECT Id, Base_Price__c FROM SF_Price_List_Item__c WHERE Id =:pliId];
        List<SF_Quote_Line_Item__c> qlis = [SELECT Id, Product__c, Quantity__c, Total_Price__c FROM SF_Quote_Line_Item__c WHERE Price_List_Item__c =:pliId];
        List<SF_QuantityRange__c> ranges = [SELECT Id, Quantity_From__c, Quantity_To__c, Price__c, Price_List_Item__c FROM SF_QuantityRange__c WHERE Price_List_Item__c =:pliId];
        
        for(SF_Quote_Line_Item__c qli : qlis) {
            for(SF_QuantityRange__c range : ranges) {
                for(SF_Price_List_Item__c pli : plis) {
                    if(qli.Quantity__c >= range.Quantity_From__c && qli.Quantity__c <= range.Quantity_To__c) {
                        qli.Total_Price__c = range.Price__c * qli.Quantity__c;
                        pli.Base_Price__c = range.Price__c;
                    }
                }
            } 
        }

        System.debug(qlis + '@@@@@@@@@Sweeft');
    }
}