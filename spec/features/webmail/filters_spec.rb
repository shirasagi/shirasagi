require 'spec_helper'

describe "webmail_filters", type: :feature, dbscope: :example, imap: true, js: true do
  let(:item_title) { "rspec-#{unique_id}" }

  shared_examples "webmail filters flow" do
    context "with auth" do
      before { login_webmail_imap }

      it "#index" do
        visit index_path

        # new/create
        click_link I18n.t('ss.links.new')
        within "form#item-form" do
          fill_in "item[name]", with: item_title
          fill_in "item[conditions][][value]", with: item_title
          select I18n.t('webmail.box.inbox'), from: "item[mailbox]"
          #find("option[value='INBOX']").select_option
        end
        click_button I18n.t('ss.buttons.save')
        wait_for_notice I18n.t("ss.notice.saved")
        click_link I18n.t('ss.links.back_to_index')

        # edit/update
        click_link item_title
        click_link I18n.t('ss.links.edit')
        wait_for_js_ready
        click_button I18n.t('ss.buttons.save')
        wait_for_notice I18n.t("ss.notice.saved")

        # apply filter
        find(".apply-mailbox option[value='INBOX']").select_option
        find(".apply-filter").click
        page.accept_confirm

        # delete/destroy
        click_link I18n.t('ss.links.delete')
        click_button I18n.t('ss.buttons.delete')
        wait_for_notice I18n.t("ss.notice.deleted")

        expect(current_path).to eq index_path
      end
    end
  end

  describe "webmail_mode is account" do
    let(:index_path) { webmail_filters_path(account: 0) }

    it_behaves_like 'webmail filters flow'
  end

  describe "webmail_mode is group" do
    let(:group) { create :webmail_group }
    let(:index_path) { webmail_filters_path(account: group.id, webmail_mode: :group) }

    before { webmail_imap.add_to_set(group_ids: [ group.id ]) }

    it_behaves_like 'webmail filters flow'
  end
end
