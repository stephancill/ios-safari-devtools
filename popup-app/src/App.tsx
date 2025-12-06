import { Ban } from "lucide-react"
import { useCallback, useEffect, useState } from "react"
import { Console } from "@/components/Console"
import { Network } from "@/components/Network"
import type { LogEntry, NetworkEntry } from "@/types"

function App() {
  const [tab, setTab] = useState<string>("console")
  const [logs, setLogs] = useState<LogEntry[]>([])
  const [requests, setRequests] = useState<NetworkEntry[]>([])

  useEffect(() => {
    // Request initial data from background script
    browser.runtime.sendMessage({ type: "GET_DATA" }).then((response) => {
      if (response) {
        setLogs(response.logs ?? [])
        setRequests(response.requests ?? [])
      }
    })

    // Listen for updates from background script
    const handleMessage = (msg: unknown) => {
      const message = msg as {
        type: string
        log?: LogEntry
        request?: NetworkEntry
      }
      if (message.type === "NEW_LOG" && message.log) {
        const log = message.log
        setLogs((prev) => [...prev, log])
      } else if (message.type === "NEW_REQUEST" && message.request) {
        const request = message.request
        setRequests((prev) => {
          const existing = prev.findIndex((r) => r.id === request.id)
          if (existing >= 0) {
            const updated = [...prev]
            updated[existing] = request
            return updated
          }
          return [...prev, request]
        })
      }
    }

    browser.runtime.onMessage.addListener(handleMessage)
    return () => browser.runtime.onMessage.removeListener(handleMessage)
  }, [])

  const handleExecute = useCallback(async (code: string) => {
    const [activeTab] = await browser.tabs.query({
      active: true,
      currentWindow: true,
    })
    if (activeTab?.id) {
      browser.tabs.sendMessage(activeTab.id, {
        type: "EXECUTE_JS",
        code,
      })
    }
  }, [])

  const handleClear = () => {
    if (tab === "console") {
      setLogs([])
      browser.runtime.sendMessage({ type: "CLEAR_LOGS" })
    } else {
      setRequests([])
      browser.runtime.sendMessage({ type: "CLEAR_REQUESTS" })
    }
  }

  return (
    <div className="devtools-panel w-full h-screen flex flex-col">
      {/* DevTools toolbar */}
      <div className="devtools-tabs flex items-center">
        <div className="flex">
          <button
            type="button"
            className="devtools-tab"
            data-state={tab === "console" ? "active" : "inactive"}
            onClick={() => setTab("console")}
          >
            Console
          </button>
          <button
            type="button"
            className="devtools-tab"
            data-state={tab === "network" ? "active" : "inactive"}
            onClick={() => setTab("network")}
          >
            Network
          </button>
        </div>
        <div className="flex-1" />
        <button
          type="button"
          className="toolbar-btn flex items-center gap-1"
          onClick={handleClear}
        >
          <Ban size={14} />
        </button>
      </div>

      {/* Content area */}
      <div className="flex-1 overflow-hidden">
        {tab === "console" ? (
          <Console logs={logs} onExecute={handleExecute} />
        ) : (
          <Network requests={requests} />
        )}
      </div>
    </div>
  )
}

export default App
