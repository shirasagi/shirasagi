import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    $(() => {
      const $element = $(this.element);
      SS.renderAjaxBox($element);
      SS_SearchUI.render($element);
      if ("Gws_Member" in window) {
        Gws_Member.render($element);
      }
    });
  }
}
