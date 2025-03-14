import SelectBoxController from "./select_box_controller";
import DropArea from "../../ss/drop_area";
import {dispatchEvent, replaceChildren} from "../../ss/tool";

export default class extends SelectBoxController {
  static values = {
    selectApi: String,
  }
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

  deleteFile(ev) {
    this.element.querySelector(".file-id").value = '';
    this.element.querySelector(".humanized-name").textContent = '';
    this.element.querySelector(".sanitizer-status").classList.add("hide");
    this.element.querySelector(".btn-file-delete").classList.add("hide");
    this.element.querySelector(".upload-drop-notice").classList.remove("hide");

    dispatchEvent(this.element, "change");
  }

  async _renderResult(selectedItems) {
    if (!selectedItems || selectedItems.length === 0) {
      return;
    }

    for(const selectedItem of selectedItems) {
      const api = this.selectApiValue.replaceAll(':id', selectedItem.id);
      const response = await fetch(api);
      if (response.ok) {
        const result = await response.json();
        console.log(result);
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

          sanitizerStatusElement.classList.add(`sanitizer-${result["sanitizer_state"]}`);
          sanitizerStatusElement.textContent = result["sanitizer_state_label"];
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
