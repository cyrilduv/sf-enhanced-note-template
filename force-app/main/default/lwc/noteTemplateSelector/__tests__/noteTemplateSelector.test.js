import { createElement } from "lwc";
import NoteTemplateSelector from "c/noteTemplateSelector";
import getTemplates from "@salesforce/apex/NoteTemplateController.getTemplates";
import saveNote from "@salesforce/apex/NoteTemplateController.saveNote";
import { ShowToastEventName } from "lightning/platformShowToastEvent";

jest.mock(
    "@salesforce/apex/NoteTemplateController.getTemplates",
    () => ({ default: jest.fn() }),
    { virtual: true }
);
jest.mock(
    "@salesforce/apex/NoteTemplateController.saveNote",
    () => ({ default: jest.fn() }),
    { virtual: true }
);

const MOCK_TEMPLATES = [
    {
        Id: "m00000000000001",
        Label: "Follow-up email sent",
        Category__c: "Follow-up",
        Template_Body__c: "<p>Email was sent to the contact.</p>",
        Sort_Order__c: 1
    },
    {
        Id: "m00000000000002",
        Label: "Stalled deal check-in",
        Category__c: "Follow-up",
        Template_Body__c: "<p>Checked in on stalled deal.</p>",
        Sort_Order__c: 2
    },
    {
        Id: "m00000000000003",
        Label: "Discovery call notes",
        Category__c: "Sales",
        Template_Body__c: "<p>Key discussion points:</p>",
        Sort_Order__c: 1
    }
];

function flushPromises() {
    return new Promise((resolve) => setTimeout(resolve, 0));
}

function createComponent() {
    const element = createElement("c-note-template-selector", {
        is: NoteTemplateSelector
    });
    element.recordId = "006000000000001";
    document.body.appendChild(element);
    return element;
}

afterEach(() => {
    while (document.body.firstChild) {
        document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
});

describe("c-note-template-selector", () => {
    describe("wire - loading templates", () => {
        it("renders template buttons on successful load", async () => {
            getTemplates.mockResolvedValue(MOCK_TEMPLATES);
            const element = createComponent();
            await flushPromises();

            const buttons = element.shadowRoot.querySelectorAll(
                "lightning-button[data-id]"
            );
            expect(buttons.length).toBe(3);
            expect(buttons[0].label).toBe("Follow-up email sent");
        });

        it("renders category headers", async () => {
            getTemplates.mockResolvedValue(MOCK_TEMPLATES);
            const element = createComponent();
            await flushPromises();

            const categories = element.shadowRoot.querySelectorAll(
                ".category-label"
            );
            const labels = Array.from(categories).map(
                (el) => el.textContent
            );
            expect(labels).toContain("Follow-up");
            expect(labels).toContain("Sales");
        });

        it("shows error toast when wire fails", async () => {
            getTemplates.mockRejectedValue(new Error("Network error"));
            const element = createComponent();
            const handler = jest.fn();
            element.addEventListener(ShowToastEventName, handler);
            await flushPromises();

            expect(handler).toHaveBeenCalledTimes(1);
            expect(handler.mock.calls[0][0].detail.variant).toBe("error");
        });

        it("renders empty state when no templates exist", async () => {
            getTemplates.mockResolvedValue([]);
            const element = createComponent();
            await flushPromises();

            const buttons = element.shadowRoot.querySelectorAll(
                "lightning-button[data-id]"
            );
            expect(buttons.length).toBe(0);
        });
    });

    describe("template selection", () => {
        it("shows editor view when a template is clicked", async () => {
            getTemplates.mockResolvedValue(MOCK_TEMPLATES);
            const element = createComponent();
            await flushPromises();

            const btn = element.shadowRoot.querySelector(
                'lightning-button[data-id="m00000000000001"]'
            );
            btn.click();
            await flushPromises();

            const titleInput =
                element.shadowRoot.querySelector("lightning-input");
            expect(titleInput).not.toBeNull();
            expect(titleInput.value).toBe("Follow-up email sent");

            const richText = element.shadowRoot.querySelector(
                "lightning-input-rich-text"
            );
            expect(richText).not.toBeNull();
            expect(richText.value).toBe(
                "<p>Email was sent to the contact.</p>"
            );
        });

        it("returns to picker view when back is clicked", async () => {
            getTemplates.mockResolvedValue(MOCK_TEMPLATES);
            const element = createComponent();
            await flushPromises();

            const btn = element.shadowRoot.querySelector(
                'lightning-button[data-id="m00000000000001"]'
            );
            btn.click();
            await flushPromises();

            const backBtn =
                element.shadowRoot.querySelector(".back-btn");
            backBtn.click();
            await flushPromises();

            const titleInput =
                element.shadowRoot.querySelector("lightning-input");
            expect(titleInput).toBeNull();
        });
    });

    describe("saving notes", () => {
        it("calls saveNote and shows success toast", async () => {
            getTemplates.mockResolvedValue(MOCK_TEMPLATES);
            saveNote.mockResolvedValue("068000000000001");
            const element = createComponent();
            await flushPromises();

            const btn = element.shadowRoot.querySelector(
                'lightning-button[data-id="m00000000000001"]'
            );
            btn.click();
            await flushPromises();

            const handler = jest.fn();
            element.addEventListener(ShowToastEventName, handler);

            const saveBtn = element.shadowRoot.querySelector(
                'lightning-button[data-id="m00000000000001"]'
            );
            // Find save button by variant
            const allButtons =
                element.shadowRoot.querySelectorAll("lightning-button");
            const saveBtnEl = Array.from(allButtons).find(
                (b) => b.variant === "brand"
            );
            saveBtnEl.click();
            await flushPromises();

            expect(saveNote).toHaveBeenCalledWith({
                title: "Follow-up email sent",
                body: "<p>Email was sent to the contact.</p>",
                recordId: "006000000000001"
            });
            expect(handler).toHaveBeenCalledTimes(1);
            expect(handler.mock.calls[0][0].detail.variant).toBe("success");
        });

        it("shows error toast when save fails", async () => {
            getTemplates.mockResolvedValue(MOCK_TEMPLATES);
            saveNote.mockRejectedValue({
                body: { message: "Insufficient access" }
            });
            const element = createComponent();
            await flushPromises();

            const btn = element.shadowRoot.querySelector(
                'lightning-button[data-id="m00000000000001"]'
            );
            btn.click();
            await flushPromises();

            const handler = jest.fn();
            element.addEventListener(ShowToastEventName, handler);

            const allButtons =
                element.shadowRoot.querySelectorAll("lightning-button");
            const saveBtnEl = Array.from(allButtons).find(
                (b) => b.variant === "brand"
            );
            saveBtnEl.click();
            await flushPromises();

            expect(handler).toHaveBeenCalledTimes(1);
            expect(handler.mock.calls[0][0].detail.variant).toBe("error");
            expect(handler.mock.calls[0][0].detail.message).toBe(
                "Insufficient access"
            );
        });

        it("shows validation warning when title is empty", async () => {
            getTemplates.mockResolvedValue([
                {
                    Id: "m00000000000004",
                    Label: "",
                    Category__c: "General",
                    Template_Body__c: "<p>body</p>",
                    Sort_Order__c: 1
                }
            ]);
            const element = createComponent();
            await flushPromises();

            const btn = element.shadowRoot.querySelector(
                'lightning-button[data-id="m00000000000004"]'
            );
            btn.click();
            await flushPromises();

            const handler = jest.fn();
            element.addEventListener(ShowToastEventName, handler);

            const allButtons =
                element.shadowRoot.querySelectorAll("lightning-button");
            const saveBtnEl = Array.from(allButtons).find(
                (b) => b.variant === "brand"
            );
            saveBtnEl.click();
            await flushPromises();

            expect(saveNote).not.toHaveBeenCalled();
            expect(handler).toHaveBeenCalledTimes(1);
            expect(handler.mock.calls[0][0].detail.variant).toBe("warning");
        });
    });
});
