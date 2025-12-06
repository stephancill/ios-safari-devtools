import { useEffect, useRef, useState } from "react"
import type { LogEntry } from "../types"

interface ConsoleProps {
  logs: LogEntry[]
  onExecute: (code: string) => void
}

// Replace smart quotes and other problematic characters with their ASCII equivalents
const sanitizeCode = (code: string): string => {
  return code
    .replace(/[\u201C\u201D\u201E\u201F\u2033\u2036]/g, '"') // smart double quotes
    .replace(/[\u2018\u2019\u201A\u201B\u2032\u2035]/g, "'") // smart single quotes
    .replace(/\u2026/g, "...") // ellipsis
    .replace(/[\u2013\u2014]/g, "-") // en-dash, em-dash
}

export function Console({ logs, onExecute }: ConsoleProps) {
  const [input, setInput] = useState("")
  const logsEndRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    logsEndRef.current?.scrollIntoView({ behavior: "smooth" })
  }, [])

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setInput(sanitizeCode(e.target.value))
  }

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    if (input.trim()) {
      onExecute(sanitizeCode(input))
      setInput("")
    }
  }

  const getLogColor = (type: LogEntry["type"]) => {
    switch (type) {
      case "error":
        return "text-red-500"
      case "warn":
        return "text-yellow-500"
      case "info":
        return "text-blue-500"
      default:
        return ""
    }
  }

  const formatArg = (arg: unknown): string => {
    if (arg === null) return "null"
    if (arg === undefined) return "undefined"
    if (typeof arg === "object") {
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
      <div className="flex-1 overflow-auto p-2 text-xs select-text">
        {logs.length === 0 ? (
          <div className="text-gray-500">No logs yet</div>
        ) : (
          logs.map((log) => (
            <div key={log.id} className={`mb-1 ${getLogColor(log.type)}`}>
              <span className="text-gray-500 mr-2">
                {new Date(log.timestamp).toLocaleTimeString()}
              </span>
              <span className="whitespace-pre-wrap">
                {log.args.map(formatArg).join(" ")}
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
            onChange={handleChange}
            placeholder="Enter JavaScript..."
            className="flex-1 bg-transparent outline-none text-sm"
            autoComplete="off"
            autoCapitalize="off"
            autoCorrect="off"
            spellCheck={false}
          />
          <button type="submit" className="text-sm px-2">
            Run
          </button>
        </div>
      </form>
    </div>
  )
}
