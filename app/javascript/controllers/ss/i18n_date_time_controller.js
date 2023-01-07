import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.pickerElement = this.element.querySelector(".js-date,.js-datetime")
    if (!this.pickerElement) {
      return
    }

    this.hiddenElement = this.element.querySelector("[type='hidden']")
    if (!this.hiddenElement) {
      return;
    }

    const $pickerElement = $(this.pickerElement)
    $pickerElement.on("ss:changeDateTime", (ev, currentTime, $input, originalEv) => this.updateHiddenAndFire(currentTime, $input, originalEv))

    const pickerInstance = SS_DateTimePicker.instance(this.pickerElement)
    if (!pickerInstance || !pickerInstance.initialized) {
      $pickerElement.one("ss:generate", () => this.updateHidden())
    } else {
      this.updateHidden()
    }
  }

  updateHidden() {
    this.hiddenElement.value = SS_DateTimePicker.valueForExchange(this.pickerElement)
  }

  updateHiddenAndFire(currentTime, $input, originalEv) {
    this.updateHidden()
    $(this.hiddenElement).trigger("ss:changeDateTime", [ currentTime, $input, originalEv ]);
  }
}
