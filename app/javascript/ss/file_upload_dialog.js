import Dialog from "./dialog";
import { dispatchEvent } from "./tool";

export default class FileUploadDialog extends Dialog {
  static showModal(src, { source = undefined, files = undefined } = {}) {
    const dialog = new FileUploadDialog(src, { source, files })
    return dialog.showModal()
  }

  async showModal() {
    const ret = super.showModal();

    if (this.options && this.options.files) {
      this._dialogFrame._dialog.addEventListener("ss:tempFile:connected", (ev) => {
        const tempFilesElement = ev.target;
        dispatchEvent(tempFilesElement, "ss:tempFile:upload", { files: this.options.files });
      }, { once: true });
    }

    return ret;
  }
}
