import { useState, useEffect, useCallback } from 'react'
import { Console } from './components/Console'
import { Network } from './components/Network'
import type { LogEntry, NetworkEntry } from './types'

type Tab = 'console' | 'network'

function App() {
  const [tab, setTab] = useState<Tab>('console')
  const [logs, setLogs] = useState<LogEntry[]>([])
  const [requests, setRequests] = useState<NetworkEntry[]>([])

  useEffect(() => {
    // Request initial data from background script
    browser.runtime.sendMessage({ type: 'GET_DATA' }).then((response) => {
      if (response) {
        setLogs(response.logs ?? [])
        setRequests(response.requests ?? [])
      }
    })

    // Listen for updates from background script
    const handleMessage = (msg: unknown) => {
      const message = msg as { type: string; log?: LogEntry; request?: NetworkEntry }
      if (message.type === 'NEW_LOG' && message.log) {
        setLogs((prev) => [...prev, message.log!])
      } else if (message.type === 'NEW_REQUEST' && message.request) {
        setRequests((prev) => {
          const existing = prev.findIndex((r) => r.id === message.request!.id)
          if (existing >= 0) {
            const updated = [...prev]
            updated[existing] = message.request!
            return updated
          }
          return [...prev, message.request!]
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
        type: 'EXECUTE_JS',
        code,
      })
    }
  }, [])

  const handleClear = () => {
    if (tab === 'console') {
      setLogs([])
      browser.runtime.sendMessage({ type: 'CLEAR_LOGS' })
    } else {
      setRequests([])
      browser.runtime.sendMessage({ type: 'CLEAR_REQUESTS' })
    }
  }

  return (
    <div className="w-80 h-96 flex flex-col text-sm">
      <div className="flex border-b border-gray-700">
        <button
          onClick={() => setTab('console')}
          className={`flex-1 py-1 ${tab === 'console' ? 'bg-gray-800' : ''}`}
        >
          Console
        </button>
        <button
          onClick={() => setTab('network')}
          className={`flex-1 py-1 ${tab === 'network' ? 'bg-gray-800' : ''}`}
        >
          Network
        </button>
        <button onClick={handleClear} className="px-2 text-gray-500">
          Clear
        </button>
      </div>
      <div className="flex-1 overflow-hidden">
        {tab === 'console' ? (
          <Console logs={logs} onExecute={handleExecute} />
        ) : (
          <Network requests={requests} />
        )}
      </div>
    </div>
  )
}

export default App
