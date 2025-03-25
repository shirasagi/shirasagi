const CSS_CLASS = 'file-dragenter';

export default class DropArea {
  constructor(element, callback) {
    this.element = element;
    this.callback = callback;

    this.element.addEventListener("dragenter", (ev) => {
      // In order to have the drop event occur on a div element, you must cancel the ondragenter and ondragover
      // https://stackoverflow.com/questions/21339924/drop-event-not-firing-in-chrome
      ev.preventDefault();

      this.#onDragEnter(ev);
    });
    this.element.addEventListener("dragleave", (ev) => {
      this.#onDragLeave(ev);
    });
    this.element.addEventListener("dragover", (ev) => {
      // In order to have the drop event occur on a div element, you must cancel the ondragenter and ondragover
      // https://stackoverflow.com/questions/21339924/drop-event-not-firing-in-chrome
      ev.preventDefault();

      this.#onDragOver(ev);
    });
    this.element.addEventListener("drop", (ev) => {
      ev.preventDefault();
      this.#onDrop(ev);
    });
  }

  #onDragEnter(_ev) {
    this.element.classList.add(CSS_CLASS);
  }

  #onDragLeave(_ev) {
    this.element.classList.remove(CSS_CLASS);
  }

  #onDragOver(_ev) {
    if (!this.element.classList.contains(CSS_CLASS)) {
      this.element.classList.add(CSS_CLASS);
    }
  }

  #onDrop(ev) {
    const files = ev.dataTransfer.files;
    this.callback(files);
    this.element.classList.remove(CSS_CLASS);
  }
}
