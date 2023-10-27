import { LightningElement, api, track, wire } from 'lwc';
import standard from './templates/standard.html';
import text from './templates/customOutputFieldText.html';
import error from './templates/error.html';
export default class CustomOutputField extends LightningElement {
	@api fieldName;
	@api label;
	@api helptext;
	@api customFieldType;
	@track formDensityClass = 'slds-form-element slds-form-element_horizontal';
	@track outputField;

	@api
	setValueOnLoad(value) {
		if (!this.outputField) {
			console.warn(`Custom Field ${this.fieldName} not loaded`);
			return;
		}

		this.template.querySelector('lightning-formatted-text').value = value;
	}

	@api
	setFormDensityHorizontal() {
		this.formDensityClass = 'slds-form-element slds-form-element_horizontal';
	}

	@api
	setFormDensityStacked() {
		this.formDensityClass = 'slds-form-element slds-form-element_stacked';
	}

	render() {
		if (this.isStandard) {
			return standard;
		} else if (this.isText) {
			return text;
		}
		return error;
	}

	get isStandard() {
		return !this.customFieldType || this.customFieldType === 'Standard';
	}

	get isText() {
		return this.customFieldType === 'TextArea' || this.customFieldType === 'Text';
	}

	get hasError() {
		return !this.isText && !this.isStandard;
	}

	handleSlotChange(event) {
		this.outputField = this.querySelector('lightning-output-field');
		//this.template.querySelector('lightning-formatted-text').value = this.querySelector('lightning-formatted-text').innerText;
	}
}
