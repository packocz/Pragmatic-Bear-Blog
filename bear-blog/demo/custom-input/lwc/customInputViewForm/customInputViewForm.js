import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getUiDensitySetting from '@salesforce/apex/UserDensitySettingController.getRunningUserUiDensitySetting';
import descriptionHelptext from '@salesforce/label/c.CustomDescriptionHelptext';
import emailHelptext from '@salesforce/label/c.CustomEmailHelptext';
import emailLabel from '@salesforce/label/c.CustomEmailLabel';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import ACCOUNT_OBJECT from '@salesforce/schema/Account';

export default class CustomInputViewForm extends LightningElement {
	@api recordId;
	isLoading = false;
	stackedBreakpoint = 660;
	accountInfo;

	@wire(getUiDensitySetting) density;

	@wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })
	accountInfo;

	get densitySetting() {
		return this.density.data ? this.density.data : 'VIEW_TWO';
	}

	get isAlwaysStacked() {
		return this.densitySetting === 'VIEW_ONE';
	}

	get labels() {
		return {
			Email__c: { helptext: emailHelptext, label: emailLabel },
			Description: { helptext: descriptionHelptext, label: this.accountInfo?.data?.fields['Description']?.label }
		};
	}

	connectedCallback() {
		window.addEventListener('resize', this.handleScreenSizeChange);
	}

	handleScreenSizeChange = () => {
		this.adjustFormForDensitySetting();
	};

	adjustFormForDensitySetting() {
		const rect = this.template.querySelector('lightning-card').getBoundingClientRect();
		this.width = rect.width;
		let allCustomInputOutputComponents = [
			...this.template.querySelectorAll('c-custom-output-field'),
			...this.template.querySelectorAll('c-custom-input-field')
		];
		allCustomInputOutputComponents.forEach((element) => {
			if (this.width > this.stackedBreakpoint && !this.isAlwaysStacked) {
				element.setFormDensityHorizontal();
			} else {
				element.setFormDensityStacked();
			}
		});
	}

	handleEditOnLoad(event) {
		this.adjustFormForDensitySetting();
		this.template.querySelectorAll('c-custom-input-field').forEach((element) => {
			element.fetchCurrentValueOnLoad();
		});
	}

	handleUpdateAccount(event) {
		this.isLoading = true;
		this.template.querySelector('lightning-record-edit-form').submit();
	}

	handleSubmitSuccess(event) {
		this.isLoading = false;
		this.dispatchEvent(
			new ShowToastEvent({
				title: 'Success',
				message: 'Succesfully saved',
				variant: 'success'
			})
		);
	}

	handleSubmitError(event) {
		this.isLoading = false;
		let topLevelError = event.detail?.message;
		if (topLevelError) {
			topLevelError = 'Error';
		} else {
			topLevelError = event.detail?.detail;
		}
		let fieldErrors = event.detail?.output?.fieldErrors;
		if (fieldErrors) {
			for (const [fieldName, errorDetails] of Object.entries(fieldErrors)) {
				let fieldQuery = 'c-custom-input-field[data-field-name=' + fieldName + ']';
				let customField = this.template.querySelector(fieldQuery);
				if (customField) {
					customField.setError(errorDetails[0].message);
				}
			}
		}
		this.dispatchEvent(
			new ShowToastEvent({
				title: 'Error while saving.',
				message: topLevelError,
				variant: 'error',
				mode: 'sticky'
			})
		);
	}
}
