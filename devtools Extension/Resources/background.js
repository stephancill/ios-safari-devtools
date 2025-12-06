// DevTools Background Script
// Acts as message broker and stores captured data

const state = {
  logs: [],
  requests: [],
};

const MAX_ENTRIES = 500;

// Send message to native app handler
function sendToNative(message) {
  browser.runtime
    .sendNativeMessage("application.id", message)
    .catch((error) => {
      // Native messaging may fail if app is not running - that's okay
      console.debug("Native message failed:", error);
    });
}

browser.runtime.onMessage.addListener((message, sender, sendResponse) => {
  const tabId = sender.tab?.id;
  const tabURL = sender.tab?.url;

  switch (message.type) {
    case "CONSOLE_LOG":
      if (message.log) {
        state.logs.push(message.log);
        if (state.logs.length > MAX_ENTRIES) {
          state.logs.shift();
        }
        // Broadcast to popup
        browser.runtime
          .sendMessage({
            type: "NEW_LOG",
            log: message.log,
          })
          .catch(() => {});

        // Send to native app for persistent storage
        if (tabId !== undefined && tabURL) {
          sendToNative({
            type: "STORE_LOG",
            log: message.log,
            tabId: tabId,
            tabURL: tabURL,
          });
        }
      }
      break;

    case "NETWORK_REQUEST":
      if (message.request) {
        const existingIndex = state.requests.findIndex(
          (r) => r.id === message.request.id
        );
        if (existingIndex >= 0) {
          // Merge with existing request (preserve startTime)
          state.requests[existingIndex] = {
            ...state.requests[existingIndex],
            ...message.request,
            startTime: state.requests[existingIndex].startTime,
          };
        } else {
          state.requests.push(message.request);
          if (state.requests.length > MAX_ENTRIES) {
            state.requests.shift();
          }
        }
        // Broadcast to popup
        browser.runtime
          .sendMessage({
            type: "NEW_REQUEST",
            request:
              existingIndex >= 0
                ? state.requests[existingIndex]
                : message.request,
          })
          .catch(() => {});

        // Send to native app for persistent storage
        if (tabId !== undefined && tabURL) {
          sendToNative({
            type: "STORE_NETWORK",
            request: message.request,
            tabId: tabId,
            tabURL: tabURL,
          });
        }
      }
      break;

    case "GET_DATA":
      return Promise.resolve({
        logs: state.logs,
        requests: state.requests,
      });

    case "CLEAR_LOGS":
      state.logs = [];
      break;

    case "CLEAR_REQUESTS":
      state.requests = [];
      break;
  }
});

// Clean up when tab closes
browser.tabs.onRemoved.addListener((tabId) => {
  sendToNative({
    type: "TAB_CLOSED",
    tabId: tabId,
  });
});

// Periodic sync: clean up orphaned tabs (e.g., extension was disabled when tabs closed)
async function syncActiveTabs() {
  try {
    const tabs = await browser.tabs.query({});
    const activeTabIds = tabs.map((t) => t.id).filter((id) => id !== undefined);
    sendToNative({
      type: "SYNC_ACTIVE_TABS",
      activeTabIds: activeTabIds,
    });
  } catch (error) {
    console.debug("Failed to sync active tabs:", error);
  }
}

// Run sync on extension startup and periodically
syncActiveTabs();
setInterval(syncActiveTabs, 5 * 60 * 1000); // Every 5 minutes
