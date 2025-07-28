// jQuery's fast is 200ms
import i18next from "i18next";

export const ANIMATE_FAST = "0.2s"

// jQuery's normal is 400ms
export const ANIMATE_NORMAL = "0.4s"

// jQuery's slow is 600ms
export const ANIMATE_SLOW = "0.6s"

export const LOADING = `<img src="/assets/img/loading.gif" width="16" height="11">`

export const LIST_ITEM_SELECTOR = ".list-item[data-id]";
export const CHECKED_LIST_ITEM_SELECTOR = ".list-item[data-id]:has(input:checked)";

export function csrfToken(el) {
  if (el && 'form' in el && el.form) {
    const authenticityTokenEl = el.form.querySelector("[name='authenticity_token']")
    if (authenticityTokenEl) {
      return authenticityTokenEl.value
    }
  }
  const csrfTokenEl = document.querySelector('meta[name="csrf-token"]')
  if (!csrfTokenEl) {
    return
  }

  return csrfTokenEl.getAttribute('content')
}

export function dispatchEvent(element, eventName, detail) {
  const event = new CustomEvent(eventName, { bubbles: true, cancelable: true, composed: true, detail: detail })
  element.dispatchEvent(event)
  return event
}

export function findTarget(element, selector) {
  if (element.matches(selector)) {
    return element;
  }

  const target = element.closest(selector);
  if (target) {
    return target;
  }

  return undefined;
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

function toUrlSafeBase64(base64String) {
  return base64String.replaceAll("+", "-").replaceAll("/", "_");
}

function fromUrlSafeBase64(urlSafeBase64String) {
  return urlSafeBase64String.replaceAll("-", "+").replaceAll("_", "/");
}

function appendBase64Padding(base64String) {
  return base64String + Array((4 - base64String.length % 4) % 4 + 1).join('=');
}

function removeBase64Padding(base64String) {
  return base64String.replace(/=+$/, '');
}

function toUTF8(str) {
  const encoder = new TextEncoder();
  const uint8Array = encoder.encode(str);
  return String.fromCodePoint(...uint8Array);
}

function fromUTF8(str) {
  const uint8Array =  Uint8Array.from(Array.prototype.map.call(str, (x) => {
    return x.charCodeAt(0);
  }));
  const decoder = new TextDecoder();
  return decoder.decode(uint8Array);
}

export function objecToUrlSafeBase64(object, { padding = true }) {
  const stringifyObject = JSON.stringify(object);
  const utf8String = toUTF8(stringifyObject);
  const base64String = btoa(utf8String);
  if (!padding) {
    return toUrlSafeBase64(removeBase64Padding(base64String));
  } else {
    return toUrlSafeBase64(base64String);
  }
}

export function urlSafeBase64ToObject(base64String) {
  const base64StringWithPadding = appendBase64Padding(base64String);
  const utf8String = atob(fromUrlSafeBase64(base64StringWithPadding));
  const stringifyObject = fromUTF8(utf8String);
  return JSON.parse(stringifyObject);
}

export function replaceChildren(element, htmlTextOrNode) {
  if (typeof htmlTextOrNode === 'string') {
    element.innerHTML = htmlTextOrNode;
  } else {
    element.replaceChildren(htmlTextOrNode);
  }

  // execute javascript within element
  element.querySelectorAll("script").forEach((scriptElement) => {
    const newScriptElement = document.createElement("script");
    Array.from(scriptElement.attributes).forEach(attr => newScriptElement.setAttribute(attr.name, attr.value));
    newScriptElement.appendChild(document.createTextNode(scriptElement.innerHTML));
    scriptElement.parentElement.replaceChild(newScriptElement, scriptElement);
  });
}

function _cloneNode(htmlTextOrNode) {
  if (htmlTextOrNode instanceof HTMLTemplateElement) {
    return htmlTextOrNode.content.cloneNode(true);
  }

  const dummyElement = document.createElement("template");
  if (htmlTextOrNode instanceof HTMLElement) {
    dummyElement.innerHTML = htmlTextOrNode.innerHTML;
  } else {
    dummyElement.innerHTML = htmlTextOrNode.toString();
  }
  return dummyElement.content.cloneNode(true);
}

function _markScriptAsNew(element) {
  element.querySelectorAll("script").forEach((scriptElement) => scriptElement.dataset.new = true);
}

function _executeNewScript(element) {
  element.querySelectorAll("script[data-new]").forEach((scriptElement) => {
    const newScriptElement = document.createElement("script");
    delete scriptElement.dataset.new;
    Array.from(scriptElement.attributes).forEach(attr => newScriptElement.setAttribute(attr.name, attr.value));
    newScriptElement.appendChild(document.createTextNode(scriptElement.innerHTML));
    scriptElement.parentElement.replaceChild(newScriptElement, scriptElement);
  });
}

export function appendChildren(element, htmlTextOrNode) {
  const dummyElement = _cloneNode(htmlTextOrNode);
  _markScriptAsNew(dummyElement);

  element.appendChild(dummyElement);
  _executeNewScript(element);
}

export function prependChildren(element, htmlTextOrNode) {
  const dummyElement = _cloneNode(htmlTextOrNode);
  _markScriptAsNew(dummyElement);

  element.prepend(dummyElement);
  _executeNewScript(element);
}

export function appendAfter(element, htmlTextOrNode) {
  if (!element.nextElementSibling) {
    appendChildren(element.parentElement, htmlTextOrNode);
    return;
  }

  const dummyElement = _cloneNode(htmlTextOrNode);
  _markScriptAsNew(dummyElement);

  element.parentElement.insertBefore(dummyElement, element.nextElementSibling)
  _executeNewScript(element);
}

export function showErrorInListItem(listItemElement, fetchResponse, errorMessages) {
  let ajaxResultElement = listItemElement.querySelector(".ss-ajax-result");
  if (ajaxResultElement) {
    ajaxResultElement.innerHTML = '';
  } else {
    ajaxResultElement = document.createElement("div");
    ajaxResultElement.classList.add("ss-ajax-result");
    listItemElement.appendChild(ajaxResultElement);
  }
  ajaxResultElement.classList.remove("ss-ajax-success");
  ajaxResultElement.classList.add("ss-ajax-failure");

  const errorContainerElement = document.createElement("div");
  errorContainerElement.classList.add("errorExplanation");

  const errorHeaderElement = document.createElement("h2");
  errorHeaderElement.textContent = i18next.t("errors.template.header.one");
  errorContainerElement.appendChild(errorHeaderElement);

  const errorBodyElement = document.createElement("p");
  errorBodyElement.textContent = i18next.t("errors.template.body");
  errorContainerElement.appendChild(errorBodyElement);

  const errorListElement = document.createElement("ul");
  if (errorMessages && errorMessages.length > 0) {
    errorMessages.forEach((error) => {
      const errorElement = document.createElement("li");
      errorElement.textContent = error;
      errorListElement.appendChild(errorElement);
    });
  } else {
    const errorElement = document.createElement("li");
    errorElement.textContent = "error";
    errorListElement.appendChild(errorElement);
  }
  errorContainerElement.appendChild(errorListElement);
  ajaxResultElement.appendChild(errorContainerElement);
}
