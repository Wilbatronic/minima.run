// Popup controller
document.getElementById('ask').addEventListener('click', () => {
    const query = document.getElementById('query').value;
    if (query) {
        browser.runtime.sendNativeMessage('com.minima.app', {
            command: 'ask',
            query: query
        });
        window.close();
    }
});

document.getElementById('summarize').addEventListener('click', () => {
    browser.tabs.query({ active: true, currentWindow: true }).then(tabs => {
        browser.tabs.sendMessage(tabs[0].id, { action: 'getContent' }).then(response => {
            browser.runtime.sendNativeMessage('com.minima.app', {
                command: 'summarize',
                content: response.content
            });
            window.close();
        });
    });
});

document.getElementById('extract').addEventListener('click', () => {
    browser.tabs.query({ active: true, currentWindow: true }).then(tabs => {
        browser.tabs.sendMessage(tabs[0].id, { action: 'getContent' }).then(response => {
            browser.runtime.sendNativeMessage('com.minima.app', {
                command: 'extract',
                content: response.content
            });
            window.close();
        });
    });
});

document.getElementById('translate').addEventListener('click', () => {
    browser.tabs.query({ active: true, currentWindow: true }).then(tabs => {
        browser.tabs.sendMessage(tabs[0].id, { action: 'getSelection' }).then(response => {
            browser.runtime.sendNativeMessage('com.minima.app', {
                command: 'translate',
                content: response.selection
            });
            window.close();
        });
    });
});
