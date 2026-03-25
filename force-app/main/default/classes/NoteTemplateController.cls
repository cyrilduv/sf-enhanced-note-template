public with sharing class NoteTemplateController {

    @AuraEnabled(cacheable=true)
    public static List<Note_Template__mdt> getTemplates(Id recordId) {
        String objectApiName = recordId.getSObjectType().getDescribe().getName();
        return [
            SELECT Id, Label, Category__c, Template_Body__c, Sort_Order__c
            FROM Note_Template__mdt
            WHERE Is_Active__c = true
              AND Object_API_Name__c = :objectApiName
            ORDER BY Sort_Order__c ASC NULLS LAST, Category__c
        ];
    }

    @AuraEnabled
    public static Id saveNote(String title, String body, Id recordId) {
        try {
            ContentNote note = new ContentNote();
            note.Title   = title;
            note.Content = Blob.valueOf(body != null ? body : '');
            insert note;

            ContentDocumentLink link = new ContentDocumentLink();
            link.ContentDocumentId = note.Id;
            link.LinkedEntityId    = recordId;
            link.ShareType         = 'V';
            link.Visibility        = 'AllUsers';
            insert link;

            return note.Id;
        } catch (Exception e) {
            throw new AuraHandledException(
                'Error saving note: ' + e.getMessage());
        }
    }
}
