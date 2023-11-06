import { Controller } from "@hotwired/stimulus"
import i18next from 'i18next'

const CONTACT_ATTRIBUTES = [
  "contact_group_name", "contact_charge", "contact_tel", "contact_fax", "contact_email", "contact_link_url", "contact_link_name"
]

export default class extends Controller {
  initialize() {
  }

  connect() {
    const $el = $(this.element)
    $el.find(".ajax-box").data("on-select", ($item) => this.selectItem($item))
    $el.find("[name=\"item[contact_group_relation]\"]").on("change", (ev) => this.changeGroupRelation(ev))
  }

  disconnect() {
  }

  selectItem($item) {
    SS_SearchUI.defaultSelector($item)

    const $el = $(this.element)
    const $data = $item.closest("[data-id]")

    const contactGroupRelation = $el.find("[name=\"item[contact_group_relation]\"]").val()
    if (contactGroupRelation === "unrelated") {
      SS.notice(i18next.t("contact.notices.unchanged_contacts"))
      return
    }

    const groupName = $data.data("contact-group-name")
    $el.find('[name="item[contact_group_name]"]').val(groupName || '');

    const chargeName = $data.data("contact-charge")
    $el.find('[name="item[contact_charge]"]').val(chargeName || '');

    const tel = $data.data("contact-tel")
    $el.find('[name="item[contact_tel]"]').val(tel || '');

    const fax = $data.data("contact-fax")
    $el.find('[name="item[contact_fax]"]').val(fax || '');

    const email = $data.data("contact-email");
    $el.find('[name="item[contact_email]"]').val(email || '');

    const linkUrl = $data.data("contact-link-url");
    $el.find('[name="item[contact_link_url]"]').val(linkUrl || '');

    const linkName = $data.data("contact-link-name");
    $el.find('[name="item[contact_link_name]"]').val(linkName || '');
  }

  changeGroupRelation(ev) {
    const $el = $(this.element)
    const disabled = ev.target.value === "related"

    CONTACT_ATTRIBUTES.forEach((item) => {
      $el.find(`[name="item[${item}]"]`).prop("disabled", disabled)
    })
  }
}
