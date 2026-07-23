import Initializer from "../ss/initializer"
import Cropper from 'cropperjs'

export default class extends Initializer {
  initialize() {
    return Promise.resolve()
  }

  afterInitialize() {
    window.Cropper = Cropper
  }
}
