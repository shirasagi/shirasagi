import { Controller } from "@hotwired/stimulus"
import { smoothDnD } from 'smooth-dnd';

export default class extends Controller {
  connect() {
    smoothDnD(this.element, { lockAxis: "y" })
  }
}
