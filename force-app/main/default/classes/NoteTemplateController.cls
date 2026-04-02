/**
 * @description Controller for the Note Template Selector LWC.
 * Provides methods to retrieve note templates and save notes to records.
 */
public with sharing class NoteTemplateController {

    /**
     * @description Returns active Note_Template__mdt records whose Object_API_Name__c
     * matches the SObject type of the given recordId.
     * @param recordId The record to look up templates for
     * @return List of matching active templates ordered by Sort_Order__c
     */
    @AuraEnabled(cacheable=true)
    public static List<Note_Template__mdt> getTemplates(Id recordId) {
        SObjectType sObjType = recordId.getSObjectType();
        String objectApiName = String.valueOf(sObjType);
        return [
            SELECT Id, Label, Category__c, Template_Body__c, Sort_Order__c
            FROM Note_Template__mdt
            WHERE Is_Active__c = true
              AND Object_API_Name__c = :objectApiName
            WITH SECURITY_ENFORCED
            ORDER BY Sort_Order__c ASC NULLS LAST, Category__c
        ];
    }

    /**
     * @description Creates a ContentNote with the given title and body, then links it
     * to the specified record via ContentDocumentLink.
     * @param title    The note title (required)
     * @param body     The rich-text note body
     * @param recordId The record to attach the note to
     * @return The Id of the newly created ContentNote
     */
    @AuraEnabled
    public static Id saveNote(String title, String body, Id recordId) {
        if (String.isBlank(title)) {
            AuraHandledException ex = new AuraHandledException('Title is required');
            ex.setMessage('Title is required');
            throw ex;
        }
        try {
            ContentNote note = new ContentNote();
            note.Title   = title;
            note.Content = Blob.valueOf(body != null ? body : '');
            SObjectAccessDecision noteDecision = Security.stripInaccessible(AccessType.CREATABLE, new List<ContentNote>{ note });
            insert noteDecision.getRecords();
            Id noteId = noteDecision.getRecords()[0].Id;

            ContentDocumentLink link = new ContentDocumentLink();
            link.ContentDocumentId = noteId;
            link.LinkedEntityId    = recordId;
            link.ShareType         = 'V';
            link.Visibility        = 'AllUsers';
            SObjectAccessDecision linkDecision = Security.stripInaccessible(AccessType.CREATABLE, new List<ContentDocumentLink>{ link });
            insert linkDecision.getRecords();

            return noteId;
        } catch (Exception e) {
            throw new AuraHandledException(
                'Error saving note: ' + e.getMessage());
        }
    }
}
