import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import getTemplates from '@salesforce/apex/NoteTemplateController.getTemplates';
import saveNote     from '@salesforce/apex/NoteTemplateController.saveNote';

export default class NoteTemplateSelector extends LightningElement {

    @api recordId;

    @track templates        = [];
    @track noteTitle        = '';
    @track noteBody         = '';
    @track templateSelected = false;
    @track isLoading        = true;
    @track isSaving         = false;

    richTextFormats = [
        'font', 'size', 'bold', 'italic', 'underline',
        'strike', 'list', 'indent', 'align', 'link', 'clean'
    ];

    // Wire: templates filtered by object type
    @wire(getTemplates, { recordId: '$recordId' })
    wiredTemplates({ error, data }) {
        if (data) {
            this.templates = data;
            this.isLoading = false;
        } else if (error) {
            this.showToast('Error', 'Could not load templates', 'error');
            this.isLoading = false;
        }
    }

    // Group templates by category for the picker UI
    get groupedTemplates() {
        const defaultOrder = 999;
        const sorted = [...this.templates].sort((itemA, itemB) => {
            const orderDiff = (itemA.Sort_Order__c ?? defaultOrder) - (itemB.Sort_Order__c ?? defaultOrder);
            if (orderDiff !== 0) {
                return orderDiff;
            }
            return (itemA.Category__c || 'General').localeCompare(itemB.Category__c || 'General');
        });
        const groups = new Map();
        sorted.forEach((template) => {
            const cat = template.Category__c || 'General';
            if (!groups.has(cat)) {
                groups.set(cat, { category: cat, templates: [] });
            }
            groups.get(cat).templates.push(template);
        });
        return [...groups.values()];
    }

    // Event handlers
    handleTemplateSelect(event) {
        const selectedId = event.target.dataset.id;
        const tmpl = this.templates.find((template) => template.Id === selectedId);
        if (!tmpl) {
            return;
        }

        this.noteTitle        = tmpl.Label;
        this.noteBody         = tmpl.Template_Body__c || '';
        this.templateSelected = true;
    }

    handleTitleChange(event) {
        this.noteTitle = event.target.value;
    }

    handleBodyChange(event) {
        this.noteBody = event.target.value;
    }

    handleBack() {
        this.templateSelected = false;
        this.noteTitle        = '';
        this.noteBody         = '';
    }

    async handleSave() {
        if (!this.noteTitle.trim()) {
            this.showToast('Validation', 'Please enter a title for the note', 'warning');
            return;
        }
        this.isSaving = true;
        try {
            await saveNote({
                body:     this.noteBody,
                recordId: this.recordId,
                title:    this.noteTitle
            });
            this.showToast('Success', 'Note saved successfully', 'success');
            getRecordNotifyChange([{ recordId: this.recordId }]);
            this.handleBack();
        } catch (error) {
            this.showToast(
                'Error',
                error.body?.message || 'Save failed — please try again',
                'error'
            );
        } finally {
            this.isSaving = false;
        }
    }

    // Helpers
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ message, title, variant }));
    }
}
