import Initializer from "../ss/initializer"

export default class extends Initializer {
  initialize() {
    return new Promise(resolve => {
      window.addEventListener('DOMContentLoaded', () => {
        resolve()
      })
    })
  }
}
