import { LightningElement, api, track, wire } from 'lwc';
import standard from './templates/standard.html';
import textArea from './templates/customInputTextArea.html';
import input from './templates/customInput.html';
import error from './templates/error.html';

export default class CustomlightningInputField extends LightningElement {
	@api fieldName;
	@api label;
	@api required;
	@api disabled;
	@api helptext;
	@api customFieldType;
	@track variant = 'label-inline';
	@track lightningInputField;
	customInput;

	@api
	fetchCurrentValueOnLoad() {
		if (!this.lightningInputField) {
			console.warn(`Custom Field ${this.fieldName} not loaded`);
			return;
		}
		if (this.isTextArea) {
			this.customInput = this.template.querySelector('lightning-textarea');
			this.customInput.value = this.lightningInputField.value;
		} else if (this.isGeneric) {
			this.customInput = this.template.querySelector('lightning-input');
			this.customInput.value = this.lightningInputField.value;
		}
	}

	@api
	setFormDensityHorizontal() {
		this.variant = 'label-inline';
	}

	@api
	setFormDensityStacked() {
		this.variant = 'label-stacked';
	}

	@api
	setError(errorMessage) {
		this.customInput.setCustomValidity(errorMessage);
		this.customInput.reportValidity();
	}

	@api
	clearError() {
		this.customInput.setCustomValidity('');
		this.customInput.reportValidity();
	}

	render() {
		if (this.isStandard) {
			return standard;
		}
		if (this.isTextArea) {
			return textArea;
		}
		if (this.isGeneric) {
			return input;
		}
		return error;
	}

	get isStandard() {
		return !this.customFieldType || this.customFieldType === 'standard';
	}

	get isTextArea() {
		return this.customFieldType === 'textarea';
	}

	get isAddress() {
		return this.customFieldType === 'address';
	}

	get isGeneric() {
		return (
			this.customFieldType === 'checkbox' ||
			this.customFieldType === 'checkbox-button' ||
			this.customFieldType === 'date' ||
			this.customFieldType === 'datetime' ||
			this.customFieldType === 'time' ||
			this.customFieldType === 'email' ||
			this.customFieldType === 'tel' ||
			this.customFieldType === 'url' ||
			this.customFieldType === 'number'
		);
	}

	get hasError() {
		return !this.isTextArea && !this.isStandard;
	}

	handleSlotChange(event) {
		this.lightningInputField = this.querySelector('lightning-input-field');
		this.lightningInputField.required = this.required;
		this.lightningInputField.disabled = this.disabled;
	}

	handleChange(event) {
		// set the hidden field to the UI state
		if (this.lightningInputField) {
			this.lightningInputField.value = event.target.value;
			this.clearError();
		}
	}
}
