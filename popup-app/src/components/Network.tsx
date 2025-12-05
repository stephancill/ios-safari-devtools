import { useState } from 'react'
import type { NetworkEntry } from '../types'

interface NetworkProps {
  requests: NetworkEntry[]
}

export function Network({ requests }: NetworkProps) {
  const [selected, setSelected] = useState<NetworkEntry | null>(null)

  const getStatusColor = (status?: number) => {
    if (!status) return 'text-gray-500'
    if (status >= 200 && status < 300) return 'text-green-500'
    if (status >= 300 && status < 400) return 'text-blue-500'
    if (status >= 400) return 'text-red-500'
    return ''
  }

  const formatDuration = (entry: NetworkEntry) => {
    if (!entry.endTime) return '...'
    return `${entry.endTime - entry.startTime}ms`
  }

  const formatBody = (body: string | null | undefined) => {
    if (!body) return null
    try {
      const parsed = JSON.parse(body)
      return JSON.stringify(parsed, null, 2)
    } catch {
      return body
    }
  }

  if (selected) {
    return (
      <div className="h-full overflow-auto text-xs">
        <div className="p-2 border-b border-gray-700">
          <button onClick={() => setSelected(null)} className="text-blue-400">
            ← Back
          </button>
        </div>
        <div className="p-2 space-y-3">
          <div>
            <div className="text-gray-500 mb-1">General</div>
            <div>
              <span className="text-gray-500">URL: </span>
              <span className="break-all">{selected.url}</span>
            </div>
            <div>
              <span className="text-gray-500">Method: </span>
              {selected.method}
            </div>
            <div>
              <span className="text-gray-500">Status: </span>
              <span className={getStatusColor(selected.status)}>
                {selected.status} {selected.statusText}
              </span>
            </div>
            <div>
              <span className="text-gray-500">Duration: </span>
              {formatDuration(selected)}
            </div>
            {selected.error && (
              <div className="text-red-500">Error: {selected.error}</div>
            )}
          </div>

          {selected.requestHeaders &&
            Object.keys(selected.requestHeaders).length > 0 && (
              <div>
                <div className="text-gray-500 mb-1">Request Headers</div>
                {Object.entries(selected.requestHeaders).map(([k, v]) => (
                  <div key={k} className="break-all">
                    <span className="text-gray-500">{k}: </span>
                    {v}
                  </div>
                ))}
              </div>
            )}

          {selected.requestBody && (
            <div>
              <div className="text-gray-500 mb-1">Request Body</div>
              <pre className="whitespace-pre-wrap break-all">
                {formatBody(selected.requestBody)}
              </pre>
            </div>
          )}

          {selected.responseHeaders &&
            Object.keys(selected.responseHeaders).length > 0 && (
              <div>
                <div className="text-gray-500 mb-1">Response Headers</div>
                {Object.entries(selected.responseHeaders).map(([k, v]) => (
                  <div key={k} className="break-all">
                    <span className="text-gray-500">{k}: </span>
                    {v}
                  </div>
                ))}
              </div>
            )}

          {selected.responseBody && (
            <div>
              <div className="text-gray-500 mb-1">Response Body</div>
              <pre className="whitespace-pre-wrap break-all">
                {formatBody(selected.responseBody)}
              </pre>
            </div>
          )}
        </div>
      </div>
    )
  }

  return (
    <div className="h-full overflow-auto p-2 text-xs">
      {requests.length === 0 ? (
        <div className="text-gray-500">No network requests yet</div>
      ) : (
        <div className="space-y-1">
          {requests.map((req) => (
            <div
              key={req.id}
              onClick={() => setSelected(req)}
              className="flex gap-2 cursor-pointer hover:bg-gray-800 p-1 -m-1 rounded"
            >
              <span className="w-12 text-gray-500">{req.method}</span>
              <span className={`w-10 ${getStatusColor(req.status)}`}>
                {req.status ?? '...'}
              </span>
              <span className="w-14 text-gray-500">{formatDuration(req)}</span>
              <span className="flex-1 truncate">
                {req.error ? (
                  <span className="text-red-500">{req.error}</span>
                ) : (
                  req.url
                )}
              </span>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
