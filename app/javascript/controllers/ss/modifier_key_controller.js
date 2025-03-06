import { Controller } from "@hotwired/stimulus"

const instances = new Set();

let initialized = false;

function initialize() {
  if(initialized) {
    return;
  }

  initialized = true;
  document.addEventListener("keydown", (ev) => {
    instances.forEach((instance, _key, _set) => instance.update(ev));
  });
}

export default class extends Controller {
  connect() {
    initialize();
    if (!instances.includes(this)) {
      instances.add(this);
    }
  }

  disconnect() {
    instances.delete(this);
  }

  update(ev) {
    const modifierKeys = [];
    if (ev.altKey) {
      modifierKeys.push("alt");
    }
    if (ev.ctrlKey) {
      modifierKeys.push("ctrl");
    }
    if (ev.metaKey) {
      modifierKeys.push("meta");
    }
    if (ev.shiftKey) {
      modifierKeys.push("shift");
    }

    this.element.setAttribute("data-modifier-keys", modifierKeys.join(" "));
  }
}
