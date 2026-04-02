# sf-enhanced-note-template

<img width="831" height="420" alt="image" src="https://github.com/user-attachments/assets/175b53fe-7f46-4c3f-b71b-7b6760043fe6" />

**INSTALLATION**

<a href="https://githubsfdeploy.herokuapp.com?owner=cyrilduv&repo=sf-enhanced-note-template&ref=main">
  <img alt="Deploy to Salesforce" src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png">
</a>

**Or deploy via Salesforce CLI:**

Sandbox:
```bash
sf project deploy start --manifest manifest/package.xml -o <your-org-alias>
```

Production (runs only the included test class instead of all tests in the org):
```bash
sf project deploy start --manifest manifest/package.xml -o <your-org-alias> --test-level RunSpecifiedTests --tests NoteTemplateControllerTest
```

> **Note:** The one-click deploy button works best with sandboxes. For production deployments, use the CLI command above — it runs only the package's test class (`NoteTemplateControllerTest`) instead of all local tests in the org, avoiding failures caused by unrelated tests.

## Note Template Selector

A generic Lightning Web Component that lets users create standardised Notes on any Salesforce record using pre-defined templates managed in Custom Metadata. Templates are automatically filtered by object type — no code changes needed to support new objects.

---

## Components

| Component | Type | Path |
|---|---|---|
| `NoteTemplateController` | Apex Class | `force-app/main/default/classes/NoteTemplateController.cls` |
| `NoteTemplateControllerTest` | Apex Test Class | `force-app/main/default/classes/NoteTemplateControllerTest.cls` |
| `noteTemplateSelector` | Lightning Web Component | `force-app/main/default/lwc/noteTemplateSelector/` |
| `Note_Template__mdt` | Custom Metadata Type | `force-app/main/default/objects/Note_Template__mdt/` |
| `Note_Template_Selector` | Permission Set | `force-app/main/default/permissionsets/Note_Template_Selector.permissionset-meta.xml` |

---

## Custom Metadata Type — `Note_Template__mdt`

All templates for all objects are managed in a single Custom Metadata Type. The `Object_API_Name__c` field determines which object each template belongs to.

### Fields

| Field API Name | Type | Purpose |
|---|---|---|
| `Label` | Text (standard) | Display name of the template (also used as default note title) |
| `Object_API_Name__c` | Text | API name of the object this template applies to (e.g. `Opportunity`, `Case`) |
| `Category__c` | Text | Groups templates in the picker UI (e.g. "Follow-up", "Settlement") |
| `Template_Body__c` | Long Text Area | HTML body of the template |
| `Sort_Order__c` | Number | Controls display order — lower numbers appear first |
| `Is_Active__c` | Checkbox | Only active templates are shown to users |

### How to Add a New Template

1. Go to **Setup > Custom Metadata Types > Note Template > Manage Records**
2. Click **New**
3. Fill in:
   - **Label** — template name
   - **Object API Name** — the API name of the target object (e.g. `Opportunity`, `Case`)
   - **Category** — grouping label
   - **Template Body** — HTML content
   - **Sort Order** — display position (lower = first)
   - **Is Active** — tick to enable
4. Click **Save**

No code deployment is required — new templates appear immediately.

---

## How It Works

### User Flow

1. The component loads on the record page and displays templates for that object, grouped by category and sorted by Sort Order
2. The user clicks a template button
3. The editor view opens with:
   - **Note Title** — pre-filled with the template label (editable)
   - **Note Body** — pre-filled with the template body (editable via rich text editor)
4. The user clicks **Save Note**
5. A ContentNote is created and linked to the record
6. A success toast is shown and the page automatically refreshes after 1.5 seconds

### Technical Flow

1. `getTemplates(Id recordId)` — Derives the object API name from the record ID, then queries active `Note_Template__mdt` records filtered by `Object_API_Name__c` (cacheable)
2. `saveNote(String title, String body, Id recordId)` — Creates a `ContentNote` and a `ContentDocumentLink` to attach it to the record
3. After save, `window.location.reload()` refreshes the page so the Notes related list updates

---

## Setup

1. Deploy all components to the target org
2. Create template records under **Setup > Custom Metadata Types > Note Template > Manage Records**
   - Set `Object_API_Name__c` to the target object API name (e.g. `Opportunity`, `Case`)
3. Add the **"Add Note from Template"** component to the record page via Lightning App Builder
4. Assign the **Note Template Selector** permission set to users

---

## Adding the Component to a Record Page

The same component is used on every object:

1. Navigate to any record of the target object
2. Click the **gear icon > Edit Page** to open Lightning App Builder
3. Drag the **"Add Note from Template"** component onto the desired location
4. Click **Save** and **Activate** (assign to org default, app, or record type as needed)

The component supports desktop and mobile form factors.

---

## Adding Support for a New Object

No code changes or deployments required:

1. Create template records under **Setup > Custom Metadata Types > Note Template > Manage Records** with the appropriate `Object_API_Name__c` value
2. Add the **"Add Note from Template"** component to the object's record page via Lightning App Builder
3. Assign the **Note Template Selector** permission set to users who need access

---

## Security & Sharing

- The Apex controller uses `with sharing`, so it respects the running user's record access
- Notes are created with `ShareType = 'V'` (Viewer) and `Visibility = 'AllUsers'`
- A **Permission Set** (`Note_Template_Selector`) grants Apex class access — assign it to users who need the component
- Users also need:
  - Read access to the record
  - Permission to create ContentNote records (standard in most profiles)

---

## Test Coverage

The `NoteTemplateControllerTest` class covers the following scenarios:

| Test Method | What It Validates |
|---|---|
| `testGetTemplatesForOpportunity` | Templates query returns a non-null list when called with an Opportunity ID |
| `testSaveNoteOnOpportunity` | Note is created with correct title and linked to the Opportunity |
| `testSaveNoteHandlesNullBody` | Null body is handled gracefully without errors |

---

## Change Set Components

When deploying to production, include the following in the change set:

| Type | Component Name |
|---|---|
| Apex Class | `NoteTemplateController` |
| Apex Class | `NoteTemplateControllerTest` |
| Lightning Web Component | `noteTemplateSelector` |
| Custom Metadata Type | `Note_Template__mdt` |
| Custom Metadata Record | `Note_Template.Name_of_Template` |
| Custom Metadata Record | `Note_Template.Follow_up_email_sent` |
| Custom Metadata Record | `Note_Template.Stalled_deal_check_in` |
| Permission Set | `Note_Template_Selector` |

When validating, run specified tests: `NoteTemplateControllerTest`

---

## Maintenance

- **Deactivating a template:** Untick `Is_Active__c` on the Custom Metadata record — no deployment required.
- **Changing sort order:** Update the `Sort_Order__c` value on the Custom Metadata record. Lower numbers appear first.
- **Adding templates for a new object:** Create Custom Metadata records with the appropriate `Object_API_Name__c` value. No code changes needed.
