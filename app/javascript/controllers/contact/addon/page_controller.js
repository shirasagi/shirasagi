import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { inquiryFormEnabled: Boolean }

  initialize() {
  }

  connect() {
    const $el = $(this.element)
    $el.find(".ajax-box").data("on-select", ($item) => this.selectItem($item))
  }

  disconnect() {
  }

  selectItem($item) {
    SS_SearchUI.defaultSelector($item)

    const $el = $(this.element)
    const $data = $item.closest("[data-id]")

    const groupName = $data.data("contact-group-name")
    $el.find('[name="item[contact_charge]"]').val(groupName || '');

    const tel = $data.data("contact-tel")
    $el.find('[name="item[contact_tel]"]').val(tel || '');

    const fax = $data.data("contact-fax")
    $el.find('[name="item[contact_fax]"]').val(fax || '');

    if (!this.inquiryFormEnabledValue) {
      const email = $data.data("contact-email");
      $el.find('[name="item[contact_email]"]').val(email || '');
    }

    const linkUrl = $data.data("contact-link-url");
    $el.find('[name="item[contact_link_url]"]').val(linkUrl || '');

    const linkName = $data.data("contact-link-name");
    $el.find('[name="item[contact_link_name]"]').val(linkName || '');
  }
}
