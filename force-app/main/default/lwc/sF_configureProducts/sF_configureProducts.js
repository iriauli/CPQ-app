// Standard Imports
import { LightningElement, track, wire } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

// Apex Imports
import getAllProducts from '@salesforce/apex/SF_ConfigureProductsController.getAllProducts';
import getQuoteLineItemColumns from '@salesforce/apex/SF_ConfigureProductsController.getQuoteLineItemColumns';
import getQuoteLineItems from '@salesforce/apex/SF_ConfigureProductsController.getQuoteLineItems';
import createQuoteLineItems from '@salesforce/apex/SF_ConfigureProductsController.createQuoteLineItems';
import updateQuoteLineItemQuantity from '@salesforce/apex/SF_ConfigureProductsController.updateQuoteLineItemQuantity';
import cloneQuoteLineItems from '@salesforce/apex/SF_ConfigureProductsController.cloneQuoteLineItems';

// Custom Labels
import AddProductsButton from '@salesforce/label/c.Button_Add_Products';
import SaveButton from '@salesforce/label/c.Button_Save';
import CancelButton from '@salesforce/label/c.Button_Cancel';
import QuoteLineItems from '@salesforce/label/c.Table_Quote_Line_Items';

export default class SF_configureProducts extends NavigationMixin(LightningElement) {
    // Variables
    recordId;
    error;
    loader = false;
    isModalOpen = false;
    data;
    baseprices;
    secondprices;
    options;
    optionId = [];
    genreList;
    newPrice;

    // Modal
    products;
    allProducts = [];
    filteredProducts = [];
    productQuantity = 1;

    // Get Quote Line Items
    columns = [];
    quoteLineItems;
    quoteLineItemData = [];
    quoteLineItemKeys;
    tableItems = [];
    dataTable;

    // Create Quote Line Items
    filterProducts = [];
    rowData = [];

    // Change Quote Line Item Quantity
    optionItems;
    @track iconName = 'utility:edit';
    @track isInputDisabled = true;

    // Custom Labels
    labels = {
        AddProductsButton,
        SaveButton,
        CancelButton,
        QuoteLineItems
    }

    // Get Quote ID
    @track currentPageReference;
    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        this.currentPageReference = currentPageReference;
        this.recordId = this.currentPageReference?.state?.c__recordId;
    }

    // Get Quote Line Item Columns
    @wire(getQuoteLineItemColumns)
    getColumns(result) {
        if (result.data) {
            this.columns = result.data;
        } else if (result.error) {
            this.error = error.data;
        }
    }

    // Get Quote Line Items
    @wire(getQuoteLineItems, ({
        quoteId: '$recordId'
    }))
    retrieveItems(result) {
        this.dataTable = result;

        const bundleItems = [];
        const optionItems = [];

        if (result.data) {
            this.quoteLineItems = JSON.parse(JSON.stringify(result.data));

            this.quoteLineItems.forEach(element => {
                if (element.Is_Bundle__c) {
                    bundleItems.push(element);
                } else {
                    optionItems.push(element);
                }
            });

            bundleItems.forEach(product => {
                product['newOptions'] = [];
                optionItems.forEach(option => {
                    if (option.Quote_Line_Item__c === product.Id) {
                        product.newOptions.push(option);
                    }
                });
            });
        } else if (result.error) {
            this.error = error.data;
        }

        this.tableItems = bundleItems;
    }

    // Products List on Modal Click
    openModal() {
        this.loader = true;
        getAllProducts({
            quoteId: this.recordId
        }).then(result => {
            this.products = result;

            this.products.forEach(product => {
                if (product.isBundle === true) {
                    this.allProducts.push({
                        Id: product.Id,
                        Name: product.productName,
                        pliId: product.priceListItemId,
                        BasePrice: product.basePrice,
                        IsBundle: product.isBundle,
                        CurrencyIsoCode: product.currencyIsoCode,
                        Quantity: this.productQuantity,
                        OptionProducts: []
                    })
                }
            })

            this.products.forEach(option => {
                if (option.isBundle === false) {
                    this.allProducts.forEach(item => {
                        if (item.Id === option.productId) {
                            item.OptionProducts.push({
                                Id: option.Id,
                                parentId: option.productId,
                                Name: option.productName,
                                pliId: option.priceListItemId,
                                BasePrice: option.basePrice,
                                IsBundle: option.isBundle,
                                IsOptional: option.isOptional,
                                CurrencyIsoCode: option.currencyIsoCode,
                                Quantity: this.productQuantity
                            })
                        }
                    })
                }
            })
            this.filteredProducts.push(...this.allProducts);
        }).catch(() => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error!',
                    message: 'Error while fetching products.',
                    variant: 'error',
                })
            );
        }
        ).finally(() =>
            this.loader = false
        );
        this.isModalOpen = true;
    }
    closeModal() {
        this.isModalOpen = false;
    }

    // Client-Side Search From
    updateSearch(event) {
        const regex = new RegExp(event.target.value, 'i')
        this.allProducts = this.filteredProducts.filter(
            value => regex.test(value.Name)
        );
    }

    // Change Product Quantity
    changeProductQuantity(event) {
        const productId = event.target.dataset.id;
        const currentValue = event.target.value;

        this.allProducts.forEach(bundle => {
            bundle.OptionProducts.forEach(child => {
                if (bundle.Id === productId) {
                    bundle.Quantity = Number(currentValue);
                } else if (child.Id === productId) {
                    child.Quantity = Number(currentValue);
                    child.BasePrice *= currentValue;
                }
            });
        });
    }

    // Change Checkbox Value
    changeCheckboxValue(event) {
        const productId = event.target.dataset.id;
        const checkboxValue = event.target.checked;

        this.allProducts.forEach(bundle => {
            bundle.OptionProducts.forEach(child => {
                if (child.Id === productId) {
                    child.IsOptional = checkboxValue;
                }
            });
        });
    }

    // Create Quote Line Items
    addQuoteLineItem(event) {
        const itemIndex = event.currentTarget.dataset.index;
        this.rowData = this.allProducts[itemIndex];

        this.filterProducts = this.rowData.OptionProducts.filter(value => value.IsOptional !== false);
        this.rowData['newOptions'] = [];

        this.filterProducts.forEach(el => {
            this.rowData.newOptions.push(el);
        })

        const filterBundle = [];
        filterBundle.push({
            Id: this.rowData.Id,
            Name: this.rowData.Name,
            pliId: this.rowData.pliId,
            BasePrice: this.rowData.BasePrice,
            IsBundle: this.rowData.IsBundle,
            CurrencyIsoCode: this.rowData.CurrencyIsoCode,
            Quantity: this.rowData.Quantity
        });

        const collectedProducts = [];
        collectedProducts.push(...filterBundle, ...this.filterProducts);
        this.loader = true;

        createQuoteLineItems({
            products: collectedProducts,
            quoteId: this.recordId
        }).then(() => {
            this.loader = false;
            refreshApex(this.dataTable);

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success!',
                    message: 'Quote line items has been updated successfully.',
                    variant: 'success',
                })
            );
        }).catch(() => {
            this.loader = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error!',
                    message: 'Error while updating quote line items.',
                    variant: 'error',
                })
            );
        })
    }

    // Change Quote Line Item Quantity
    changeQuoteLineItemQuantity(event) {
        const quoteLineItemId = event.target.dataset.id;
        const currentValue = event.target.value;

        this.tableItems.forEach(bundle => {
            bundle.newOptions.forEach(child => {
                if (child.Id === quoteLineItemId) {
                    child.Quantity__c = Number(currentValue);
                    this.optionItems = child;
                }
            });
        });
    }

    // Update Quote Line Item Quantity
    quoteLineItemQuantity(event) {
        const quoteLineItemId = event.target.dataset.id;
        this.iconName = 'utility:check';
        this.isInputDisabled = false;

        if (this.optionItems.Id === quoteLineItemId) {
            updateQuoteLineItemQuantity({
                option: this.optionItems
            }).then(() => {
                refreshApex(this.dataTable);
                this.iconName = 'utility:edit';
                this.isInputDisabled = true;

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success!',
                        message: 'Quantity has been updated successfully.',
                        variant: 'success',
                    })
                );
            }).catch(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error!',
                        message: 'Error while updating quantity.',
                        variant: 'error',
                    })
                );
            })
        }
    }

    // Clone Quote Line Items
    quoteLineItemsClone(event) {
        const quoteLineItemId = event.target.dataset.id;

        cloneQuoteLineItems({
            qliId: quoteLineItemId,
        }).then(() => {
            refreshApex(this.dataTable);

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success!',
                    message: 'Quote line items has been cloned successfully.',
                    variant: 'success',
                })
            );
        }).catch(() => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error!',
                    message: 'Error while cloning quote line items.',
                    variant: 'error',
                })
            );
        })
    }

}





// bundleItems.map((items) => {
//     this.quoteLineItemData.push([
//         items.Name,
//         items.Unit_Price__c,
//         items.Subtotal__c,
//         items.Quantity__c,
//         items.Discount__c,
//         items.Total_Price__c,
//         items.CurrencyIsoCode]);
// })

// let keys = [...this.columns];
// let values = [...this.quoteLineItemData];
// console.log(this.columns);
// console.log(this.quoteLineItemData);

// this.quoteLineItemKeys = keys;
// this.quoteLineItems = values.map(value =>
//     Object.fromEntries(
//         keys.map((key, index) => ([key, value[index]]))
//     )
// );