@isTest
private class NoteTemplateControllerTest {

    @TestSetup
    static void makeData() {
        Account acc = new Account(Name = 'Fleetcare Test Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name      = 'Test Opp – Note Template',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id
        );
        insert opp;

}

    @isTest
    static void testGetTemplatesForOpportunity() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        List<Note_Template__mdt> templates =
            NoteTemplateController.getTemplates(opp.Id);
        Test.stopTest();

        System.assertNotEquals(null, templates,
            'getTemplates should never return null');
    }

    @isTest
    static void testSaveNoteOnOpportunity() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        String testTitle = 'Discovery call recap – Test';
        String testBody  = '<p>Pain points identified:</p><ul><li>Item one</li></ul>';

        Test.startTest();
        Id noteId = NoteTemplateController.saveNote(
            testTitle, testBody, opp.Id);
        Test.stopTest();

        ContentNote note = [
            SELECT Id, Title FROM ContentNote WHERE Id = :noteId
        ];
        System.assertEquals(testTitle, note.Title,
            'Note title should match');

        ContentDocumentLink link = [
            SELECT Id, LinkedEntityId, ShareType, Visibility
            FROM ContentDocumentLink
            WHERE ContentDocumentId = :noteId
              AND LinkedEntityId = :opp.Id
            LIMIT 1
        ];
        System.assertEquals(opp.Id,      link.LinkedEntityId, 'Note should be linked to the Opportunity');
        System.assertEquals('V',         link.ShareType,      'ShareType should be Viewer');
        System.assertEquals('AllUsers',  link.Visibility,     'Visibility should be AllUsers');
    }

    @isTest
    static void testSaveNoteHandlesNullBody() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        Id noteId = NoteTemplateController.saveNote(
            'Null body test', null, opp.Id);
        Test.stopTest();

        System.assertNotEquals(null, noteId,
            'A valid note Id should be returned even with null body');
    }
}
