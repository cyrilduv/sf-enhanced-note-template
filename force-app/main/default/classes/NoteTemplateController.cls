public with sharing class NoteTemplateController {

    @AuraEnabled(cacheable=true)
    public static List<Note_Template__mdt> getTemplates(Id recordId) {
        String objectApiName = recordId.getSObjectType().getDescribe().getName();
        return [
            SELECT Id, Label, Category__c, Template_Body__c, Sort_Order__c
            FROM Note_Template__mdt
            WHERE Is_Active__c = true
              AND Object_API_Name__c = :objectApiName
            WITH SECURITY_ENFORCED
            ORDER BY Sort_Order__c ASC NULLS LAST, Category__c
        ];
    }

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
