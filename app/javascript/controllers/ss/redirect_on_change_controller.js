import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.url = this.element.dataset.url;
    this.selects = this.element.querySelectorAll('select');
    this.valueElements = this.element.querySelectorAll('select, input');

    let self = this;
    this.selects.forEach(function (element) {
      element.addEventListener("change", (_) => self.redirect());
    });
  }

  redirect() {
    let redirect = this.url;
    this.valueElements.forEach(function (element) {
      let name = ":" + element.getAttribute("name") + ":";
      let escapedName = "%3A" + element.getAttribute("name") + "%3A";
      let value = element.value;
      var defaultValue = element.dataset.default || "";

      if (!value) {
        value = defaultValue;
      }
      redirect = redirect.replace(name, value).replace(escapedName, value);
    })
    location.href = redirect;
  }
}
