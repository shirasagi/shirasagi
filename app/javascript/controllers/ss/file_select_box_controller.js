import SelectBoxController from "./select_box_controller";
import {dispatchEvent, prependChildren, replaceChildren} from "../../ss/tool";
import i18next from 'i18next'
import DropArea from "../../ss/drop_area";

// アップロード順
// ※アップロード順とは、ID順のこと
function idComparator(lhs, rhs) {
  const lhsId = lhs.dataset.fileId;
  const rhsId = rhs.dataset.fileId;
  if (lhsId > rhsId) {
    return -1;
  } else if (lhsId < rhsId) {
    return 1;
  } else {
    return 0;
  }
}

function nameComparator(lhs, rhs) {
  const lhsName = lhs.dataset.name?.toLowerCase() || "";
  const rhsName = rhs.dataset.name?.toLowerCase() || "";

  if (lhsName < rhsName) {
    return -1;
  } else if (lhsName > rhsName) {
    return 1;
  } else {
    return 0;
  }
}

// ファイル選択の選択結果はとてもじゃないけど ejs でレンダリングするのは無理。
// 選択したファイルをサーバーへポストバックしてレンダリングしてもらう。
export default class extends SelectBoxController {
  static values = {
    uploadApi: String,
    fileApi: String,
    selectApi: String,
    viewApi: String
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

  openDialog(ev) {
    if (ev.target.name === "upload") {
      this.apiValue = this.uploadApiValue;
    } else {
      this.apiValue = this.fileApiValue;
    }

    super.openDialog();
  }

  openFile(ev) {
    SS_FileView.open(ev, { viewPath: this.viewApiValue });
  }

  reorderSelectedFiles(ev) {
    const comparator = ev.target.value === "name" ? nameComparator : idComparator
    const fileViewElements = Array.from(this.resultTarget.querySelectorAll(".file-view"));
    fileViewElements.sort(comparator);
    fileViewElements.forEach((fileViewElement) => {
      const removeClassList = []
      fileViewElement.classList.forEach((cssClass) => {
        if (cssClass.startsWith("animate__")) {
          removeClassList.push(cssClass);
        }
      });
      fileViewElement.classList.remove(...removeClassList);
      this.resultTarget.appendChild(fileViewElement);
    })
    dispatchEvent(this.resultTarget, "change");

    this.element.querySelectorAll(`[data-action="ss--file-select-box#reorderSelectedFiles"]`).forEach((buttonElement) => {
      if (buttonElement.value === ev.target.value) {
        buttonElement.setAttribute("aria-pressed", true);
      } else {
        buttonElement.setAttribute("aria-pressed", false);
      }
    });
  }

  attachFile(ev) {
    SS_FileView.pasteFile(ev, this.#fileViewOptions());
  }

  pasteImage(ev) {
    SS_FileView.pasteImage(ev, this.#fileViewOptions());
  }

  pasteThumbnail(ev) {
    SS_FileView.pasteThumbnail(ev, this.#fileViewOptions());
  }

  deleteFile(ev) {
    SS_FileView.deleteFile(ev, this.#fileViewOptions());
  }

  #fileViewOptions() {
    const options = {
      viewPath: this.viewApiValue,
      confirmationOnDelete: i18next.t('ss.confirm.delete'),
      inUseConfirmation: i18next.t('ss.confirm.in_use')
    };
    return options;
  }

  async _renderResult(selectedItems) {
    if (!this.hasResultTarget) {
      return;
    }
    if (!selectedItems || selectedItems.length === 0) {
      return;
    }

    if (this.selectionTypeValue === "replace" || this.selectionTypeValue === "single") {
      const overallHtml = [];
      for (const selectedItem of selectedItems) {
        const api = this.selectApiValue.replaceAll(':id', selectedItem.id);
        const response = await fetch(api);
        if (response.ok) {
          const html = await response.text();
          overallHtml.push(html);
        }
      }

      if (this.selectionTypeValue === "single") {
        replaceChildren(this.resultTarget, overallHtml[0]);
      } else {
        replaceChildren(this.resultTarget, overallHtml.join());
      }
    } else {
      // append only missing items
      const existedIds = this._selectedIds();
      const nonExistedItems = selectedItems.filter((selectedItem) => !existedIds.has(String(selectedItem.id)))
      for(const selectedItem of nonExistedItems) {
        const api = this.selectApiValue.replaceAll(':id', selectedItem.id);
        const response = await fetch(api);
        if (response.ok) {
          const html = await response.text();
          prependChildren(this.resultTarget, html);
        }
      }
    }

    dispatchEvent(this.resultTarget, "change");
  }

  _selectedIds() {
    if (!this.hasResultTarget) {
      return new Set();
    }

    const idElements = this.resultTarget.querySelectorAll("[data-file-id]");
    const ids = Array.from(idElements).map((element) => String(element.dataset.fileId));
    return new Set(ids);
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

    this.apiValue = this.uploadApiValue;
    super.openDialog();
  }
}
