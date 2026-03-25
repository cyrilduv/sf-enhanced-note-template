# sf-enhanced-note-template

## Note Template Selector

A generic Lightning Web Component that lets users create standardised Notes on any Salesforce record using pre-defined templates managed in Custom Metadata. Templates are automatically filtered by object type — no code changes needed to support new objects.

### Components

| Component | Type |
|---|---|
| `NoteTemplateController` | Apex Controller |
| `NoteTemplateControllerTest` | Apex Test Class |
| `noteTemplateSelector` | Lightning Web Component |
| `Note_Template__mdt` | Custom Metadata Type |
| `Note_Template_Selector` | Permission Set |

### Setup

1. Deploy all components to the target org
2. Create template records under **Setup > Custom Metadata Types > Note Template > Manage Records**
   - Set `Object_API_Name__c` to the target object API name (e.g. `Opportunity`, `Document_Checklist__c`)
3. Add the **"Add Note from Template"** component to the record page via Lightning App Builder
4. Assign the **Note Template Selector** permission set to users

### Adding a New Object

No code changes required:

1. Create template records with the new object's API name in `Object_API_Name__c`
2. Add the component to the object's record page
3. Assign the permission set to users

### Documentation

See [docs/Note_Template_Selector_Handover.md](docs/Note_Template_Selector_Handover.md) for the full implementation handover.
