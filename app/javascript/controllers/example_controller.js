import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  initialize() {
    console.log("example#initialize")
  }

  connect() {
    console.log("example#connect")
  }

  disconnect() {
    console.log("example#disconnect")
  }
}
