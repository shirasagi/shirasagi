// jQuery's fast is 200ms
export const ANIMATE_FAST = "0.2s"

// jQuery's normal is 400ms
export const ANIMATE_NORMAL = "0.4s"

// jQuery's slow is 600ms
export const ANIMATE_SLOW = "0.6s"

export const LOADING = `<img src="/assets/img/loading.gif" width="16" height="11">`

export function csrfToken() {
  const el = document.querySelector('meta[name="csrf-token"]')
  if (!el) {
    return
  }

  return el.getAttribute('content')
}

export function dispatchEvent(element, eventName, detail) {
  const event = new CustomEvent(eventName, { bubbles: true, cancelable: true, composed: true, detail: detail })
  element.dispatchEvent(event)
  return event
}

export function fadeOut(element, speed) {
  speed ||= ANIMATE_NORMAL

  return new Promise((resolve) => {
    element.style.setProperty('--animate-duration', speed);
    element.classList.add('animate__animated', 'animate__fadeOut')
    element.addEventListener('animationend', () => { resolve() }, { once: true })
  })
}

export function capitalize(str) {
  return str.charAt(0).toUpperCase() + str.slice(1)
}

export function isSafari() {
  const userAgent = window.navigator.userAgent.toLowerCase();
  return userAgent.indexOf("safari") !== -1
}
