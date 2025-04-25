import SelectBoxController from "./select_box_controller";
import DropArea from "../../ss/drop_area";
import {dispatchEvent} from "../../ss/tool";

export default class extends SelectBoxController {
  static targets = [
    "option",
    "fileUploadDropArea"
  ];

  connect() {
    super.connect();

    if (this.hasFileUploadDropAreaTarget) {
      new DropArea(this.fileUploadDropAreaTarget, (files) => this.#onDrop(files));
    }
  }

  optionTargetConnected(element) {
    const option = JSON.parse(element.innerHTML);
    for (const key in option) {
      this[`${key}Value`] = option[key];
    }
  }

  deleteFile(_ev) {
    const fileIdElement = this.element.querySelector(".file-id");
    if (fileIdElement) {
      fileIdElement.value = '';
    }
    const humanizedNameElement = this.element.querySelector(".humanized-name");
    if (humanizedNameElement) {
      humanizedNameElement.textContent = '';
    }
    const thumbnailImageElement = this.element.querySelector("img");
    if (thumbnailImageElement) {
      thumbnailImageElement.removeAttribute("src");
      thumbnailImageElement.removeAttribute("alt");
      thumbnailImageElement.classList.add("hide");
    }
    const dropNoticeElement = this.element.querySelector(".upload-drop-notice");
    if (dropNoticeElement) {
      dropNoticeElement.classList.remove("hide");
    }
    const fileViewElement = this.element.querySelector(".file-view");
    if (fileViewElement) {
      fileViewElement.classList.add("hide");
    }
    const fileDeleteElement = this.element.querySelector(".btn-file-delete");
    if (fileDeleteElement) {
      fileDeleteElement.classList.add("hide");
    }

    dispatchEvent(this.element, "change");
  }

  async _renderResult(selectedItems) {
    if (!selectedItems || selectedItems.length === 0) {
      return;
    }

    for(const selectedItem of selectedItems) {
      const fileIdElement = this.element.querySelector(".file-id");
      if (fileIdElement) {
        fileIdElement.value = selectedItem.id;
      }
      const humanizedNameElement = this.element.querySelector(".humanized-name");
      if (humanizedNameElement) {
        humanizedNameElement.textContent = selectedItem.humanizedName;
      }
      const sanitizerStatusElement = this.element.querySelector(".sanitizer-status");
      if (sanitizerStatusElement) {
        const removeTargets = [];
        sanitizerStatusElement.classList.forEach((cssClass) => {
          if (cssClass.startsWith("sanitizer-") && cssClass !== "sanitizer-status") {
            removeTargets.push(cssClass);
          }
        });
        if (removeTargets.length > 0) {
          sanitizerStatusElement.classList.remove(...removeTargets);
        }

        sanitizerStatusElement.classList.add(`sanitizer-${selectedItem.sanitizerState}`);
        sanitizerStatusElement.textContent = selectedItem.sanitizerStateLabel;
      }
      const thumbnailImageElement = this.element.querySelector("img");
      if (thumbnailImageElement) {
        if (selectedItem.image_) {
          thumbnailImageElement.src = selectedItem.thumbUrl;
          thumbnailImageElement.alt = selectedItem.humanizedName;
          thumbnailImageElement.classList.remove("hide");
        } else {
          thumbnailImageElement.src = "";
          thumbnailImageElement.alt = "";
          thumbnailImageElement.classList.add("hide");
        }
      }
      const dropNoticeElement = this.element.querySelector(".upload-drop-notice");
      if (dropNoticeElement) {
        dropNoticeElement.classList.add("hide");
      }
      const fileDeleteElement = this.element.querySelector(".btn-file-delete");
      if (fileDeleteElement) {
        fileDeleteElement.classList.remove("hide");
      }
    }

    dispatchEvent(this.element, "change");
  }

  _selectedIds() {
    const id = this.element.querySelector(".file-id").value;
    return new Set([ id ]);
  }

  #onDrop(files) {
    if (!files || files.length === 0) {
      return;
    }

    document.addEventListener("ss:dialog:opened", (ev) => {
      const tempFilesElement = ev.target.querySelector(".cms-temp-file");
      dispatchEvent(tempFilesElement, "ss:tempFile:upload", { files: files });
      this.fileUploadDropAreaTarget.classList.remove('file-dragenter');
    }, { once: true })

    super.openDialog();
  }
}
