import { useEffect, useRef, useState } from "react"
import type { LogEntry } from "@/types"

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

  // biome-ignore lint/correctness/useExhaustiveDependencies: scroll when logs change
  useEffect(() => {
    logsEndRef.current?.scrollIntoView({ behavior: "smooth" })
  }, [logs.length])

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

  const getRowClass = (type: LogEntry["type"]) => {
    switch (type) {
      case "error":
        return "console-row error"
      case "warn":
        return "console-row warn"
      case "info":
        return "console-row info"
      default:
        return "console-row"
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

  const formatTime = (timestamp: number) => {
    const date = new Date(timestamp)
    return date.toLocaleTimeString("en-US", {
      hour12: false,
      hour: "2-digit",
      minute: "2-digit",
      second: "2-digit",
    })
  }

  return (
    <div className="devtools-panel flex flex-col h-full">
      <div className="flex-1 overflow-auto select-text">
        {logs.length === 0 ? (
          <div className="empty-state">No logs yet</div>
        ) : (
          logs.map((log) => (
            <div key={log.id} className={getRowClass(log.type)}>
              <span className="console-timestamp">
                {formatTime(log.timestamp)}
              </span>
              <span className="console-message">
                {log.args.map(formatArg).join(" ")}
              </span>
            </div>
          ))
        )}
        <div ref={logsEndRef} />
      </div>
      <form onSubmit={handleSubmit} className="console-prompt">
        <input
          type="text"
          value={input}
          onChange={handleChange}
          autoComplete="off"
          autoCapitalize="off"
          autoCorrect="off"
          spellCheck={false}
        />
      </form>
    </div>
  )
}
