import { api, LightningElement } from 'lwc'; 
import { NavigationMixin } from 'lightning/navigation';
import cloneQuote from '@salesforce/apex/SF_LightningHelper.cloneQuote'; 

export default class SF_cloneQuote extends NavigationMixin(LightningElement) {
    @api recordId; 

    @api async invoke() { 
        const recordId = await cloneQuote({quoteId: this.recordId, wihtQuoteLineItems: true}); 
        this.handleSuccess(recordId);
    }

    handleSuccess(id) { 
        this[NavigationMixin.Navigate]({  
            type: 'standard__recordPage', 
            attributes: {
                recordId: id, 
                objectApiName: 'SF_Quote__c',
                actionName: 'edit'
            },
        })
    }
}