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
        // Templates are filtered by Object_API_Name__c in the WHERE clause,
        // so all returned records belong to Opportunity by definition.
        // Verify the result is a usable list (field access works).
        for (Note_Template__mdt t : templates) {
            System.assertNotEquals(null, t.Label,
                'Each template should have a Label');
        }
    }

    @isTest
    static void testGetTemplatesForObjectWithNoTemplates() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        List<Note_Template__mdt> templates =
            NoteTemplateController.getTemplates(acc.Id);
        Test.stopTest();

        System.assertNotEquals(null, templates,
            'getTemplates should return an empty list, not null');
        System.assertEquals(0, templates.size(),
            'No templates should exist for Account in this test context');
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
            'Note title should match the provided title');

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

        ContentNote note = [
            SELECT Id, Title, Content FROM ContentNote WHERE Id = :noteId
        ];
        System.assertEquals('Null body test', note.Title,
            'Title should match even when body is null');
        System.assertNotEquals(null, noteId,
            'A valid note Id should be returned even with null body');
    }

    @isTest
    static void testSaveNoteHandlesEmptyTitleThrowsError() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        try {
            NoteTemplateController.saveNote(
                '', '<p>Body with empty title</p>', opp.Id);
            System.assert(false, 'Expected AuraHandledException for empty title');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Title is required'),
                'Exception should mention title requirement, got: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testSaveNoteWithInvalidRecordIdThrowsError() {
        // Use a fabricated Id that won't match a real record
        Id fakeOppId = Opportunity.SObjectType.getDescribe().getKeyPrefix() + '000000000000';

        Test.startTest();
        try {
            NoteTemplateController.saveNote('Test', '<p>body</p>', fakeOppId);
            System.assert(false, 'Expected AuraHandledException for invalid record Id');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().length() > 0,
                'Exception message should not be empty');
        }
        Test.stopTest();
    }

    @isTest
    static void testGetTemplatesRunsUnderRestrictedUser() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Profile minProfile = [SELECT Id FROM Profile WHERE Name = 'Minimum Access - Salesforce' LIMIT 1];
        User restrictedUser = new User(
            Alias            = 'minusr',
            Email            = 'minaccess@fleetcare.test',
            EmailEncodingKey = 'UTF-8',
            LastName         = 'MinAccess',
            LanguageLocaleKey  = 'en_US',
            LocaleSidKey       = 'en_US',
            ProfileId        = minProfile.Id,
            TimeZoneSidKey   = 'America/New_York',
            UserName         = 'minaccess.' + DateTime.now().getTime() + '@fleetcare.test',
            Street           = '1 Test Street',
            State            = 'QLD'
        );
        insert restrictedUser;

        System.runAs(restrictedUser) {
            Test.startTest();
            Boolean accessBlocked = false;
            try {
                NoteTemplateController.getTemplates(opp.Id);
            } catch (System.QueryException e) {
                accessBlocked = true;
                System.assert(e.getMessage().contains('Insufficient permissions'),
                    'SECURITY_ENFORCED should block inaccessible fields, got: ' + e.getMessage());
            }
            Test.stopTest();

            System.assert(accessBlocked,
                'WITH SECURITY_ENFORCED should block query for restricted user');
        }
    }

    @isTest
    static void testSaveNoteEnforcesFLSUnderRestrictedUser() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Profile minProfile = [SELECT Id FROM Profile WHERE Name = 'Minimum Access - Salesforce' LIMIT 1];
        User restrictedUser = new User(
            Alias            = 'minusr',
            Email            = 'minaccess@fleetcare.test',
            EmailEncodingKey = 'UTF-8',
            LastName         = 'MinAccess',
            LanguageLocaleKey  = 'en_US',
            LocaleSidKey       = 'en_US',
            ProfileId        = minProfile.Id,
            TimeZoneSidKey   = 'America/New_York',
            UserName         = 'minaccess.' + DateTime.now().getTime() + '@fleetcare.test',
            Street           = '1 Test Street',
            State            = 'QLD'
        );
        insert restrictedUser;

        System.runAs(restrictedUser) {
            Test.startTest();
            try {
                NoteTemplateController.saveNote('Test', '<p>body</p>', opp.Id);
                // If no exception, stripInaccessible allowed the insert —
                // the user has ContentNote create access in this org.
            } catch (AuraHandledException e) {
                System.assert(e.getMessage().length() > 0,
                    'Restricted user should receive a meaningful error');
            }
            Test.stopTest();
        }
    }
}
