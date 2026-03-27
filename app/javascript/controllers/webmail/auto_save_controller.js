import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String, maxRetry: Number, firstInterval: Number, keepInterval: Number }

  #url;
  #maxRetry;
  #errorCount;
  #lastHash;
  #firstInterval;
  #keepInterval;
  #formId = "item-form";
  #editorId = "item_html";
  #noticeCount = 0;

  connect() {
    this.#url = this.urlValue
    this.#maxRetry = this.maxRetryValue;
    this.#firstInterval = this.firstIntervalValue;
    this.#keepInterval = this.keepIntervalValue;

    let self = this;
    $(function() {
      // wait CKEditor loaded and get first formData.
      self.#lastHash = self.#toHash(self.#getFormData());
      // expose autoSave function into global context for debug and rspec interface.
      window.WEBMAIL_AutoSave = self.#autoSave.bind(self);
      // start auto save.
      setTimeout(() => { self.#autoSave(); }, self.#firstInterval);
    });
  }

  #getFormData () {
    let form = document.querySelector("#" + this.#formId);
    let formData = new FormData(form);
    formData.set("item[html]", this.#getEditorHtml());
    return formData;
  }

  #getEditorHtml () {
    let html;
    if (typeof tinymce !== 'undefined') {
      html = tinymce.get(this.#editorId).getContent();
    } else if (typeof CKEDITOR !== 'undefined') {
      html = CKEDITOR.instances[this.#editorId].getData();
    } else {
      html = "";
    }
    return html;
  }

  #showNotice() {
    let $notice = $(".webmail-auto-save-notice");
    $notice.addClass("saved");
    $notice.attr("data-count", this.#noticeCount);
    $notice.animate({ opacity: 0 }, 1200, function() {
      $(this).removeClass("saved").css("opacity", 1);
    });
    this.#noticeCount += 1;
  }

  #toHash(formData) {
    return {
      subject: formData.get("item[subject]"),
      format: formData.get("item[format]"),
      text: formData.get("item[text]"),
      html: formData.get("item[html]"),
      itemTo: formData.getAll("item[to][]").filter((v) => v),
      itemCc: formData.getAll("item[cc][]").filter((v) => v),
      itemBcc: formData.getAll("item[bcc][]").filter((v) => v),
      fileIds: formData.getAll("item[file_ids][]").filter((v) => v),
    }
  }

  #sameHash(hash, lastHash) {
    if (hash && lastHash && JSON.stringify(hash) === JSON.stringify(lastHash)) {
      return true;
    } else {
      return false;
    }
  }

  #saveable(hash) {
    if (hash.subject) {
      return true;
    }
    if (hash.text || hash.html) {
      return true;
    }
    if (hash.itemTo.length > 0 || hash.itemCc.length > 0 || hash.itemBcc.length > 0){
      return true;
    };
    return false;
  }

  #autoSave() {
    let formData = this.#getFormData();
    let hash = this.#toHash(formData);

    if (this.#sameHash(hash, this.#lastHash) || !this.#saveable(hash)) {
      if (this.#keepInterval > 0) {
        setTimeout(() => { this.#autoSave(); }, this.#keepInterval);
      }
      return;
    }
    this.#lastHash = hash;

    fetch(this.#url, { method: "POST", body: formData })
    .then(response => {
      if (!response.ok) {
        throw new Error('auto save failed.');
      }
      this.#showNotice();
      this.#errorCount = 0;
    })
    .catch(error => {
      console.error(error);
      this.#errorCount += 1;
    })
    .finally(() => {
      if (this.#keepInterval > 0 && this.#errorCount < this.#maxRetry) {
        setTimeout(() => { this.#autoSave(); }, this.#keepInterval);
      }
    });
  }
}
