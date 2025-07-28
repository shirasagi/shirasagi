import { Controller } from "@hotwired/stimulus"
import Dialog from "../../../ss/dialog"

const USER_TYPE_NAMES = new Set([
  "item[approvers][][user_type]", "item[circulations][][user_type]",
  "item[workflow_approvers][][user_type]", "item[workflow_circulations][][user_type]",
])

const USER_ID_NAMES = new Set([
  "item[approvers][][user_id]", "item[circulations][][user_id]",
  "item[workflow_approvers][][user_id]", "item[workflow_circulations][][user_id]"
])

export default class extends Controller {
  connect() {
    this.selectElement = this.element.querySelector('[name="dummy-approver"],[name="dummy-circulator"]')
    if (!this.selectElement) {
      return
    }

    this.#applyDefault()
    this.prevSelectedIndex = this.selectElement.selectedIndex
    this.selectElement.addEventListener("change", (_ev) => {
      this.#changeApprover()
    })
  }

  #applyDefault() {
    const defaultUserType = this.element.dataset.defaultUserType
    const defaultUserId = this.element.dataset.defaultUserId
    const defaultUserName = this.element.dataset.defaultUserName
    if (!defaultUserType || !defaultUserId) {
      return
    }

    const defaultOptionIndex = this.#findOption(defaultUserType, defaultUserId)
    if (defaultOptionIndex >= 0) {
      this.#updateApprover(defaultUserType, defaultUserId)
      this.selectElement.selectedIndex = defaultOptionIndex
      this.prevSelectedIndex = defaultOptionIndex
      return
    }

    if (defaultUserType === "Gws::User") {
      this.#addNewOptionAndSelect(defaultUserId, defaultUserName)
    }
  }

  #changeApprover() {
    if (this.selectElement.selectedIndex < 0) {
      this.#updateApprover("", "")
      this.prevSelectedIndex = -1
      return
    }

    const option = this.selectElement.options[this.selectElement.selectedIndex]
    const value = option.value
    const type = option.dataset.type
    if (value === "select_other") {
      const dialogSource = this.element.dataset.approverPath
      Dialog.showModal(dialogSource).then(result => this.#ok(result.returnValue))
    } else {
      this.#updateApprover(type, value)
      this.prevSelectedIndex = this.selectElement.selectedIndex
    }
  }

  #updateApprover(userType, userId) {
    Array.from(this.selectElement.parentElement.children).forEach((element) => {
      if (!element.name) {
        return
      }
      if (USER_TYPE_NAMES.has(element.name)) {
        element.value = userType ? userType : ''
      }
      if (USER_ID_NAMES.has(element.name)) {
        element.value = userId
      }
    })

    const event = new CustomEvent("gws:workflow2:change-approver", {
      bubbles: true, cancelable: false, composed: true,
      detail: { userType: userType, userId: userId }
    })
    this.element.dispatchEvent(event)
  }

  #restoreApprover() {
    if (this.prevSelectedIndex < 0) {
      this.#updateApprover('', '')
      return
    }

    const option = this.selectElement.options[this.prevSelectedIndex]
    const type = option.dataset.type
    const value = option.value
    this.#updateApprover(type, value)
    this.selectElement.selectedIndex = this.prevSelectedIndex
  }

  #ok(items) {
    if (!items || !items[0]) {
      // dialog is cancelled
      this.#restoreApprover()
      return
    }

    const userId = items[0].id
    const userLongName = items[0].longName
    const optionIndex = this.#findOption("Gws::User", userId)
    if (optionIndex >= 0) {
      this.#updateApprover("Gws::User", userId)
      this.selectElement.selectedIndex = optionIndex
      this.prevSelectedIndex = optionIndex
      return
    }

    this.#addNewOptionAndSelect(userId, userLongName)
  }

  #findOption(type, userId) {
    userId = userId.toString()
    return Array.from(this.selectElement.options).findIndex((option) => {
      if (option.value === userId && option.dataset.type === type) {
        return true
      }
    })
  }

  #addNewOptionAndSelect(userId, userLongName) {
    const newOptionElement = document.createElement('option')
    newOptionElement.value = userId
    newOptionElement.dataset.type = "Gws::User"
    newOptionElement.textContent = userLongName

    const templateElement = document.querySelector(this.element.dataset.optionsTemplateRef)
    const cloneElement = templateElement.content.cloneNode(true)

    const selectOtherElement = cloneElement.querySelector('[value="select_other"]')
    cloneElement.insertBefore(newOptionElement, selectOtherElement)

    this.selectElement.replaceChildren(cloneElement)
    requestAnimationFrame(() => {
      const optionIndex = this.#findOption("Gws::User", userId)
      this.#updateApprover("Gws::User", userId)
      this.selectElement.selectedIndex = optionIndex
      this.selectElement.classList.remove("blank-value")
      this.prevSelectedIndex = optionIndex
    })
  }
}
