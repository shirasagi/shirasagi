import { Controller } from "@hotwired/stimulus"

function isInputText(el) {
  return el.tagName === "INPUT" && el.type === "text";
}

function isTextArea(el) {
  return el.tagName === "TEXTAREA";
}

function isSelect(el) {
  return el.tagName === "SELECT";
}

function isSubmit(el) {
  return (el.tagName === "INPUT" || el.tagName === "BUTTON") && el.type === "submit";
}

function isAjaxTable(el) {
  return el.classList.contains("ajax-selected");
}

function isFileView(el) {
  return el.id === "selected-files" || el.classList.contains("column-value-files");
}

export default class extends Controller {
  connect() {
    $(this.element).on("change", (ev) => {
      if (isInputText(ev.target) || isTextArea(ev.target) || isSelect(ev.target) || isAjaxTable(ev.target) || isFileView(ev.target)) {
        SS.formChanged = new Date().getTime();
      }
    }).on("ss:editorChange", (_ev) => {
      SS.formChanged = new Date().getTime();
    }).on("click", (ev) => {
      if (isSubmit(ev.target)) {
        SS.formChanged = undefined;
      }
    });
  }
}
