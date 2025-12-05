// DevTools Background Script
// Acts as message broker and stores captured data

const state = {
  logs: [],
  requests: [],
};

const MAX_ENTRIES = 500;

browser.runtime.onMessage.addListener((message, sender, sendResponse) => {
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
