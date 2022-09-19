import PopupController from "./popup_controller"

export default class extends PopupController {
  initialize() {
    super.initialize();
  }

  connect() {
    this.inlineValue = true
    this.refValue = ".tooltip-content"
    this.themeValue = "light-border ss-tooltip"

    super.connect();
  }

  disconnect() {
    super.disconnect();
  }
}
