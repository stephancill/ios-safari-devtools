// Console tests
document.getElementById('log')!.onclick = () => console.log('Hello from log')
document.getElementById('warn')!.onclick = () => console.warn('Warning message')
document.getElementById('error')!.onclick = () => console.error('Error message')
document.getElementById('info')!.onclick = () => console.info('Info message')
document.getElementById('obj')!.onclick = () =>
  console.log({ user: 'test', count: 42, nested: { a: 1, b: 2 } })

// Error tests
document.getElementById('throw')!.onclick = () => {
  throw new Error('Test runtime error')
}
document.getElementById('reject')!.onclick = () => {
  Promise.reject(new Error('Test unhandled rejection'))
}

// Network tests
document.getElementById('fetch-ok')!.onclick = () => {
  fetch('https://httpbin.org/get').then((r) => console.log('Fetch OK:', r.status))
}
document.getElementById('fetch-404')!.onclick = () => {
  fetch('https://httpbin.org/status/404').then((r) => console.log('Fetch 404:', r.status))
}
document.getElementById('fetch-fail')!.onclick = () => {
  fetch('https://invalid.domain.test/').catch((e) => console.error('Fetch failed:', e.message))
}
document.getElementById('xhr')!.onclick = () => {
  const xhr = new XMLHttpRequest()
  xhr.open('GET', 'https://httpbin.org/get')
  xhr.onload = () => console.log('XHR OK:', xhr.status)
  xhr.send()
}

console.log('Test app loaded')
