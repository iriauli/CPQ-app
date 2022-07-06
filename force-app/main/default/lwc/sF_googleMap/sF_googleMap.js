import { LightningElement,wire,api } from "lwc";
import { getRecord,updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import SF_createShippingAddress from '@salesforce/label/c.SF_createShippingAddress';
import SF_createBillingAddress from '@salesforce/label/c.SF_createBillingAddress';
import SF_save from '@salesforce/label/c.SF_save'; 

import Shipping_Street from '@salesforce/schema/Account.Shipping_Street__c';
import Shipping_Postal_Code from '@salesforce/schema/Account.Shipping_Postal_Code__c';
import Shipping_Country from '@salesforce/schema/Account.Shipping_Country__c';
import Shipping_State from '@salesforce/schema/Account.Shipping_State__c';
import Billing_Street from '@salesforce/schema/Account.Billing_Street__c';
import Billing_Postal_Code from '@salesforce/schema/Account.Billing_Postal_Code__c';
import Billing_Country from '@salesforce/schema/Account.Billing_Country__c';
import Billing_State from '@salesforce/schema/Account.Billing_State__c';
import Id_Field from '@salesforce/schema/Account.Id';

const FIELDS = [
  Shipping_Street,
  Shipping_Postal_Code, 
  Shipping_Country,
  Shipping_State,
  Billing_Street,
  Billing_Postal_Code,
  Billing_Country,
  Billing_State
];

const IS_ACTIVE = { SHIPPING:'Shipping', BILLING:'Billing' };

/**
 * @author Sandro
 */
export default class SF_googleMap extends LightningElement {
  @api recordId;
  account;

  labels = { 
    SF_createShippingAddress,
    SF_createBillingAddress,
    SF_save
  }

  street;
  city;
  country;
  province; 
  postalcode;  

  mapMarkers=[];
  showAddressForm=false;
  isActive;

  @wire(getRecord, { recordId: '$recordId', fields: FIELDS})
  wiredRecord({ error, data }) {
      if (error) {
          let message = 'Unknown error';
          if (Array.isArray(error.body)) {
              message = error.body.map(e => e.message).join(', ');
          } else if (typeof error.body.message === 'string') {
              message = error.body.message;
          }
          this.dispatchEvent(
              new ShowToastEvent({
                  title: 'Error loading contact',
                  message, 
                  variant: 'error',
              }),
          );
      } else if (data) {
          this.account = data;
      } 
  }

  handleChange(e) { 
    let {city,street,country,province,postalcode} = e.target;
    this.setAddressInformation(city,street,country,province,postalcode); 
    this.setMapMarkers();
  }

  handleSave() {
    if(!this.showAddressForm) return;

    const fields={}; 
    fields[Id_Field.fieldApiName] = this.recordId; 

    if(this.isActive === IS_ACTIVE.SHIPPING) {
      fields[Shipping_Street.fieldApiName] = this.street;
      fields[Shipping_Postal_Code.fieldApiName] = this.postalcode;
      fields[Shipping_Country.fieldApiName] = this.country;
      fields[Shipping_State.fieldApiName] = this.province;
    } else if(this.isActive === IS_ACTIVE.BILLING) { 
      fields[Billing_Street.fieldApiName] = this.street;
      fields[Billing_Postal_Code.fieldApiName] = this.postalcode;
      fields[Billing_Country.fieldApiName] = this.country;
      fields[Billing_State.fieldApiName] = this.province;
    }

    updateRecord({ fields }) 
      .then(() => { 
          this.dispatchEvent(
              new ShowToastEvent({
                  title: 'Success',
                  message: `${this.isActive} information has been updated`,
                  variant: 'success'
              })
          );
          return refreshApex(this.account);
      })
      .catch(error => {
          this.dispatchEvent(
              new ShowToastEvent({
                  title: 'Error creating record',
                  message: error.body.message,
                  variant: 'error'
              })
          );
      });
  }

  handleCreateShipping() {
    this.showAddressForm = true; 
    this.isActive = IS_ACTIVE.SHIPPING;
    let { 
      Shipping_Street__c,
      Shipping_Country__c,
      Shipping_State__c,
      Shipping_Postal_Code__c
    } = this.account.fields;

    this.setAddressInformation( 
      Shipping_Street__c.value,
      Shipping_Country__c.value,
      Shipping_State__c.value,
      Shipping_Postal_Code__c.value, 
    );
    this.setMapMarkers();
  }

  handleCreateBilling() { 
    this.showAddressForm = true;
    this.isActive = IS_ACTIVE.BILLING;
    let {
      Billing_Street__c,
      Billing_Postal_Code__c,
      Billing_Country__c,
      Billing_State__c
    } = this.account.fields;

    this.setAddressInformation(
      Billing_Street__c.value,
      Billing_Country__c.value,
      Billing_State__c.value,
      Billing_Postal_Code__c.value
    ); 
    this.setMapMarkers();
  }

  setAddressInformation(street,country,province,postalcode,city) {
    this.city = city;
    this.street = street;
    this.country = country;
    this.province = province; 
    this.postalcode = postalcode; 
  }

  setMapMarkers() {
    this.mapMarkers = [ 
      {
        location: { 
          City: this.city,
          Country: this.country,
          PostalCode: this.postalcode,
          State: this.province,
          Street: this.street,
        }
      }, 
    ];
  }
}