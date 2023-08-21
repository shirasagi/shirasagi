const REDIRECT_STATUS_CODES = [ 302, 303, 307 ]

export default class TurboFullRedirect {
  static #instance = null;

  static start() {
    if (TurboFullRedirect.#instance) {
      // already started
      return
    }

    const instance = new TurboFullRedirect()
    instance.start();
    TurboFullRedirect.#instance = instance
  }

  start() {
    document.addEventListener("turbo:before-fetch-response",  (ev) => this.#onBeforeFetchResponse(ev))
  }

  #onBeforeFetchResponse(ev) {
    if (!ev.detail || !ev.detail.fetchResponse) {
      return
    }

    const response = ev.detail.fetchResponse.response
    if (!response || !response.ok) {
      return
    }

    const contentType = response.headers.get("Content-Type")
    if (!contentType.includes("application/json")) {
      return
    }

    ev.preventDefault()
    response.json().then((json) => {
      if (json.status && REDIRECT_STATUS_CODES.includes(json.status) && json.location) {
        location.href = json.location
      }
    })
  }
}
