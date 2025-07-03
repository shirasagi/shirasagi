import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["inputType", "option"];

  connect() {
    this.element.addEventListener("change", (ev) => {
      if (this.inputTypeTargets.some((inputTypeTarget) => inputTypeTarget === ev.target)) {
        this.#onChange(ev);
      }
    });
  }

  optionTargetConnected(element) {
    this.option = JSON.parse(element.innerHTML);
  }

  #onChange(ev) {
    if (!this.option || !this.option.radioConfiguration) {
      return;
    }

    const radioConfiguration = this.option.radioConfiguration[ev.target.value];
    if (!radioConfiguration) {
      return;
    }

    Object.keys(radioConfiguration).forEach((name) => {
      const radioSetting = radioConfiguration[name];
      this.element.querySelectorAll(`[name='${name}']`).forEach((radioOrSelectElement) => {
        if (radioOrSelectElement.tagName !== "INPUT" && radioOrSelectElement.tagName !== "SELECT") {
          return;
        }

        // ラジオボタンをdisabledにすると、サーバーへ値が送信されなくなる。
        // それでは困るので hidden にサーバーへ送信する値を保持している。
        // この処理では、hidden を disabled にしないようにする。
        if (radioOrSelectElement.tagName === "INPUT" && radioOrSelectElement.type === "radio") {
          if (radioSetting.disabled !== undefined) {
            radioOrSelectElement.disabled = radioSetting.disabled;
          }
          if (radioSetting.value !== undefined && radioOrSelectElement.value && radioOrSelectElement.value === radioSetting.value) {
            radioOrSelectElement.checked = true;
          }
        } else if (radioOrSelectElement.tagName === "SELECT") {
          if (radioSetting.disabled !== undefined) {
            radioOrSelectElement.disabled = radioSetting.disabled;
          }
          if (radioSetting.value !== undefined) {
            const optionElement = radioOrSelectElement.querySelector(`option[value='${radioSetting.value}']`);
            if (optionElement) {
              optionElement.selected = true;
            }
          }
        }});
    });
  }
}
