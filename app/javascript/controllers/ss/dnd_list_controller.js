import { Controller } from "@hotwired/stimulus"
import { smoothDnD } from 'smooth-dnd';

const connected = new Set();
export default class extends Controller {
  connect() {
    if (connected.has(this.element)) {
      return;
    }

    connected.add(this.element);
    smoothDnD(this.element, { lockAxis: "y", onDrop: (dropResult) => this.#onDrop(dropResult) })

    this.element.addEventListener("change", (ev) => this.#onChange(ev));
  }

  disconnect() {
    connected.delete(this.element);
  }

  #onChange(ev) {
    if (ev.target.tagName === "SELECT") {
      // ghost 内の select の選択状態が初期になってしまうので、select の選択が変更されたら対応する option の selected 属性も変更する
      const optionElements = Array.from(ev.target.querySelectorAll("option"));
      const selectedOption = optionElements.find((optionElement) =>  optionElement.attributes["selected"]);
      if (selectedOption && selectedOption.value == ev.target.value) {
        // nothing to do
        return;
      }

      const valueOption = optionElements.find((optionElement) =>  optionElement.value === ev.target.value);
      if (valueOption) {
        if (selectedOption) {
          selectedOption.removeAttribute("selected");
        }
        valueOption.setAttribute("selected", "selected");
      }
      return;
    }

    if (ev.target.tagName === "INPUT" && ev.target.type === "radio") {
      // ラジオボタンの場合、ghost内の表示は問題ないが、ドロップした後、どのどのラジオボタンも選択されてない状態になってしまう。
      // まずは、常にラジオボタンの #checked と checked 属性とが一致するようにする。
      const radioElements = Array.from(this.element.querySelectorAll(`[name="${ev.target.name}"]`));
      const checkedRadio = radioElements.find((radioElement) => radioElement.getAttribute("checked"))
      if (checkedRadio && checkedRadio.value === ev.target.value) {
        // nothing to do
        return;
      }

      const valueRadio = radioElements.find((radioElement) => radioElement.value === ev.target.value);
      if (valueRadio) {
        if (checkedRadio) {
          checkedRadio.removeAttribute("checked")
        }
        valueRadio.setAttribute("checked", "checked")
      }
    }
  }

  #onDrop(dropResult) {
    // ラジオボタンの場合、ドロップした後、どのどのラジオボタンも選択されてない状態になってしまう。
    // 上でラジオボタンの #checked と、checked 属性とが一致するようにしているので、
    // checked 属性を元に #checked を true にする。
    const { addedIndex } = dropResult;

    const addedElement = Array.from(this.element.querySelectorAll(".smooth-dnd-draggable-wrapper"))[addedIndex];
    if (!addedElement) {
      return;
    }

    const radioButtons = Array.from(addedElement.querySelectorAll("input[type='radio']"));
    radioButtons.forEach((radioButton) => {
      if (radioButton.getAttribute("checked")) {
        radioButton.checked = true;
      }
    });
  }
}
