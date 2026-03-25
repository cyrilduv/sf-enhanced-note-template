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

    // ── Wire: templates filtered by object type (cacheable) ───────────────
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

    // ── Group templates by Category__c for the picker UI ──────────────────
    get groupedTemplates() {
        const sorted = [...this.templates].sort((a, b) => {
            const orderDiff = (a.Sort_Order__c ?? 999) - (b.Sort_Order__c ?? 999);
            if (orderDiff !== 0) return orderDiff;
            return (a.Category__c || 'General').localeCompare(b.Category__c || 'General');
        });
        const groups = new Map();
        sorted.forEach(t => {
            const cat = t.Category__c || 'General';
            if (!groups.has(cat)) {
                groups.set(cat, { category: cat, templates: [] });
            }
            groups.get(cat).templates.push(t);
        });
        return [...groups.values()];
    }

    // ── Event handlers ─────────────────────────────────────────────────────
    handleTemplateSelect(event) {
        const selectedId = event.target.dataset.id;
        const tmpl = this.templates.find(t => t.Id === selectedId);
        if (!tmpl) return;

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
                title:    this.noteTitle,
                body:     this.noteBody,
                recordId: this.recordId
            });
            this.showToast('Success', 'Note saved successfully', 'success');
            getRecordNotifyChange([{ recordId: this.recordId }]);
            setTimeout(() => {
                this.handleBack();
                window.location.reload();
            }, 1500);
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

    // ── Helpers ────────────────────────────────────────────────────────────
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
