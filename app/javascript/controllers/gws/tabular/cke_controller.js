import { Controller } from "@hotwired/stimulus"
import {dispatchEvent} from "../../../ss/tool";

const connected = new Set();

export default class extends Controller {
  static values = { config: String };

  _connected = false;

  connect() {
    if (connected.has(this.element)) {
      return;
    }

    connected.add(this.element);
    this.#enableCKEditor(() => {
      dispatchEvent(this.element, "ss:editorActivated");
    });
    this._connected = true;
  }

  disconnect() {
    if (!this._connected) {
      return;
    }

    connected.delete(this.element);

    const ckeditor = $(this.element).ckeditor();
    if (ckeditor && ckeditor.status && ckeditor.status !== 'unloaded') {
      ckeditor.destroy();
    }
  }

  #enableCKEditor(onReady) {
    const $editor = $(this.element);
    const config = {
      customConfig: this.configValue || '/.sys/apis/cke_config.js',
      on: { instanceReady: onReady }
    };

    $editor.ckeditor(config);
  }
}
