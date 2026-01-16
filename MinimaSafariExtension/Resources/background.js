// Safari Web Extension - Background Script
// This runs in the extension's background context

browser.runtime.onMessage.addListener((request, sender, sendResponse) => {
    if (request.action === "getPageContent") {
        // Get the current page's text content
        browser.tabs.executeScript({
            code: `document.body.innerText`
        }).then(results => {
            sendResponse({ content: results[0] });
        });
        return true; // Async response
    }
    
    if (request.action === "summarizePage") {
        // Send to native app for processing
        browser.runtime.sendNativeMessage("com.minima.app", {
            command: "summarize",
            content: request.content
        }).then(response => {
            sendResponse(response);
        });
        return true;
    }
});

// Context menu for "Ask Minima about selection"
browser.contextMenus.create({
    id: "askMinima",
    title: "Ask Minima about this",
    contexts: ["selection"]
});

browser.contextMenus.onClicked.addListener((info, tab) => {
    if (info.menuItemId === "askMinima" && info.selectionText) {
        // Open Minima with the selection
        browser.runtime.sendNativeMessage("com.minima.app", {
            command: "ask",
            query: info.selectionText
        });
    }
});
