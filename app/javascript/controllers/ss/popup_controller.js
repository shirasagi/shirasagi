import { Controller } from "@hotwired/stimulus"
import tippy from 'tippy.js';

let initialized = false

function initializeOnce() {
  if (initialized) {
    return;
  }

  initialized = true;

  // tippy default settings
  tippy.setDefaultProps({
    interactive: true,
    maxWidth: 'min(680px,90vw)',
    theme: 'light-border ss-popup',
    trigger: 'click',
  });
}

export default class extends Controller {
  static values = {
    html: String,
    inline: Boolean,
    overflow: Boolean,
    ref: String,
    theme: String,
  }

  initialize() {
    initializeOnce();
  }

  connect() {
    this.element.addEventListener("click", () => this.#createPopup(), { once: true })
  }

  #createPopup() {
    if (this.element._tippy) {
      // already created
      return
    }

    const result = this.inlineValue ? this.#createInlinePopup() : this.#createAjaxPopup()
    if (! result) {
      return
    }

    this.element._ss ||= {}
    this.element._ss.popup = this
    this.show();
  }

  #createInlinePopup() {
    var self = this
    var createAndShow = function(content, overflow) {
      var tippyOptions = { content: content }
      if (self.themeValue) {
        tippyOptions["theme"] = self.themeValue
      }
      if (overflow) {
        tippyOptions["popperOptions"] = { modifiers: { preventOverflow: { escapeWithReference: true } } }
      }
      tippy(self.element, tippyOptions)
    }

    if (this.htmlValue) {
      createAndShow(this.htmlValue, this.overflowValue)
      return true
    }

    if (this.refValue) {
      const content = this.element.querySelector(this.refValue) || document.querySelector(this.refValue)
      if (content) {
        createAndShow(content, this.overflowValue)
        return true
      }
    }

    return false
  }

  #createAjaxPopup() {
    if (! this.refValue) {
      return false
    }

    var tippyOptions = { content: SS.loading, trigger: 'click', theme: 'light-border ss-popup' }

    if (this.themeValue) {
      tippyOptions["theme"] = this.themeValue
    }

    if (this.overflowValue) {
      tippyOptions["popperOptions"] = { modifiers: { preventOverflow: { escapeWithReference: true } } }
    }

    tippy(this.element, tippyOptions)

    var self = this;
    axios.get(this.refValue)
      .then((response) => { this.element._tippy.setContent(response.html) })
      .catch((error) => { this.showError(error) })
  }

  showError(_error) {
    if (this.element._tippy) {
      this.element._tippy.setContent("[==Error==]")
    }
  }

  show() {
    if (this.element._tippy) {
      this.element._tippy.show()
    }
  }

  disconnect() {
  }
}
