import { useState, useEffect, useRef } from 'react'
import type { LogEntry } from '../types'

interface ConsoleProps {
  logs: LogEntry[]
  onExecute: (code: string) => void
}

export function Console({ logs, onExecute }: ConsoleProps) {
  const [input, setInput] = useState('')
  const logsEndRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    logsEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [logs])

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    if (input.trim()) {
      onExecute(input)
      setInput('')
    }
  }

  const getLogColor = (type: LogEntry['type']) => {
    switch (type) {
      case 'error':
        return 'text-red-500'
      case 'warn':
        return 'text-yellow-500'
      case 'info':
        return 'text-blue-500'
      default:
        return ''
    }
  }

  const formatArg = (arg: unknown): string => {
    if (arg === null) return 'null'
    if (arg === undefined) return 'undefined'
    if (typeof arg === 'object') {
      try {
        return JSON.stringify(arg, null, 2)
      } catch {
        return String(arg)
      }
    }
    return String(arg)
  }

  return (
    <div className="flex flex-col h-full">
      <div className="flex-1 overflow-auto p-2 text-xs">
        {logs.length === 0 ? (
          <div className="text-gray-500">No logs yet</div>
        ) : (
          logs.map((log) => (
            <div key={log.id} className={`mb-1 ${getLogColor(log.type)}`}>
              <span className="text-gray-500 mr-2">
                {new Date(log.timestamp).toLocaleTimeString()}
              </span>
              <span className="whitespace-pre-wrap">
                {log.args.map(formatArg).join(' ')}
              </span>
            </div>
          ))
        )}
        <div ref={logsEndRef} />
      </div>
      <form onSubmit={handleSubmit} className="p-2 border-t border-gray-700">
        <div className="flex gap-2">
          <input
            type="text"
            value={input}
            onChange={(e) => setInput(e.target.value)}
            placeholder="Enter JavaScript..."
            className="flex-1 bg-transparent outline-none text-sm"
          />
          <button type="submit" className="text-sm px-2">
            Run
          </button>
        </div>
      </form>
    </div>
  )
}

