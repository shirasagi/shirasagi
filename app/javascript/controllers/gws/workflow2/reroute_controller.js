import { Controller } from "@hotwired/stimulus"
import { csrfToken } from "../../../ss/tool"
import Dialog from "../../../ss/dialog"

export default class extends Controller {
  connect() {
    this.level = this.element.dataset.level
    if (!this.level) {
      console.warn("[gws/workflow2/reroute] level is missing")
      return
    }
    this.approverId = this.element.dataset.approverId
    if (!this.approverId) {
      console.warn("[gws/workflow2/reroute] approverId is missing")
      return
    }
    this.action = this.element.dataset.action
    if (!this.action) {
      console.warn("[gws/workflow2/reroute] action is missing")
      return
    }
    this.method = this.element.dataset.method
    if (!this.method) {
      console.warn("[gws/workflow2/reroute] method is missing")
      return
    }
    this.dialogSource = this.element.dataset.dialogSrc
    if (!this.dialogSource) {
      console.warn("[gws/workflow2/reroute] dialogSrc is missing")
      return
    }

    this.element.addEventListener("click", (ev) => this.#onClick(ev))
  }

  #onClick(ev) {
    ev.preventDefault()
    Dialog.showModal(this.dialogSource).then((result) => this.#ok(result))
  }

  #ok(result) {
    if (!result.returnValue) {
      return
    }
    const data = result.returnValue[0]
    const form = this.#buildForm(data.id)
    this.element.parentElement.appendChild(form)
    form.addEventListener("turbo:submit-end", () => form.remove(), { once: true });
    requestAnimationFrame(() => form.requestSubmit());
  }

  #buildForm(newApproverId) {
    const form = document.createElement("form")
    form.setAttribute("data-turbo", "true")
    form.setAttribute("action", this.action)
    form.setAttribute("method", this.method)

    const inputAuthneticityToken = document.createElement("input")
    inputAuthneticityToken.name = "authneticity_token"
    inputAuthneticityToken.type = "hidden"
    inputAuthneticityToken.value = csrfToken()
    form.appendChild(inputAuthneticityToken)

    const inputLevel = document.createElement("input")
    inputLevel.name = "item[level]"
    inputLevel.type = "hidden"
    inputLevel.value = this.level
    form.appendChild(inputLevel)

    const inputUserId = document.createElement("input")
    inputUserId.name = "item[approver_id]"
    inputUserId.type = "hidden"
    inputUserId.value = this.approverId
    form.appendChild(inputUserId)

    const inputNewUserId = document.createElement("input")
    inputNewUserId.name = "item[new_approver_id]"
    inputNewUserId.type = "hidden"
    inputNewUserId.value = newApproverId
    form.appendChild(inputNewUserId)

    return form
  }
}
