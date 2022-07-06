import { api, LightningElement, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi'; 
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createQuote from '@salesforce/apex/SF_LightningHelper.createQuote'; 
import { NavigationMixin } from 'lightning/navigation';
import OPP_ACCOUNT_ID from '@salesforce/schema/Opportunity.Account.Id';
import OPP_ACCOUNT_PRICELIST_ID from '@salesforce/schema/Opportunity.Account.Price_List__c';
import OPP_ACCOUNT_PRICELIST_NAME from '@salesforce/schema/Opportunity.Account.Price_List__r.Name';
import OPP_NAME from '@salesforce/schema/Opportunity.Name';

import success from '@salesforce/label/c.success';
import successMessage from '@salesforce/label/c.successMessage';
import unknownError from '@salesforce/label/c.unknownError';
import wireErrorTItle from '@salesforce/label/c.wireErrorTItle';  
import errorCreatingRecord from '@salesforce/label/c.errorCreatingRecord'; 

/** 
 * Headless quick action - create SF_Quote__c
 * @author Sandro 
 */
export default class SF_createQuote extends NavigationMixin(LightningElement) {
    @api recordId;
    opportunityId;
    accountId;
    priceListId;
    name; 

    labels = {  
        success,
        successMessage,
        unknownError,
        wireErrorTItle,
        errorCreatingRecord
    }

    @wire(getRecord, { recordId: '$recordId', fields: [
        OPP_ACCOUNT_ID,
        OPP_ACCOUNT_PRICELIST_ID,
        OPP_ACCOUNT_PRICELIST_NAME,
        OPP_NAME    
    ]}) 
    wiredRecord({ error, data }) { 
      if (error) {
          let message = this.labels.unknownError;
          if (Array.isArray(error.body)) {
              message = error.body.map(e => e.message).join(', ');
          } else if (typeof error.body.message === 'string') {
              message = error.body.message; 
          }
          this.dispatchEvent(
              new ShowToastEvent({ 
                  title: this.labels.wireErrorTItle,
                  message, 
                  variant: 'error',
              }),
          );  
      } else if (data) {
          this.opportunityId = this.recordId;
          this.accountId = getFieldValue(data,OPP_ACCOUNT_ID);
          this.priceListId = getFieldValue(data,OPP_ACCOUNT_PRICELIST_ID); 
          this.name = `${getFieldValue(data,OPP_NAME)} ${getFieldValue(data,OPP_ACCOUNT_PRICELIST_NAME)}`; 
    } 
  }

  @api invoke() {
    this.handleCreateQuote();
  }
 
  async handleCreateQuote() {   
    try {
        const id = await createQuote({
            accountId : this.accountId,
            name : this.name,
            opportunityId : this.opportunityId, 
            priceListId : this.priceListId,
            expirationDate : null,
            primary : true,
            status : 'Draft'
        });
        this.dispatchEvent(
            new ShowToastEvent({
                title: this.labels.success,
                message: this.labels.successMessage, 
                variant: 'success', 
            }),
        );
        this.handleSuccess(id);
    } catch (error) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: this.labels.errorCreatingRecord,
                message: error.body.message,
                variant: 'error',
            }),
        );
    }
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