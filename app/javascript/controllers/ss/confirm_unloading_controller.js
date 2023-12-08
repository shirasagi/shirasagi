import { Controller } from "@hotwired/stimulus"
import {dispatchEvent} from "../../ss/tool";

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

export default class extends Controller {
  connect() {
    $(this.element).on("change", (ev) => {
      if (isInputText(ev.target) || isTextArea(ev.target) || isSelect(ev.target)) {
        SS.formChanged = new Date().getTime();
      }
    }).on("click", (ev) => {
      if (isSubmit(ev.target)) {
        SS.formChanged = undefined;
      }
    });
  }
}
