require 'spec_helper'

describe "webmail_mailboxes", type: :feature, dbscope: :example, imap: true, js: true do
  let(:user) { webmail_imap }
  let(:item_title) { "rspec-#{unique_id}" }

  shared_examples "webmail mailboxes flow" do
    context "with auth" do
      before { login_user(user) }

      it "#index" do
        visit index_path
        expect(page).to have_content('下書き')
        expect(page).to have_content('INBOX.Draft')
        expect(page).to have_content('送信済み')
        expect(page).to have_content('INBOX.Sent')
        expect(page).to have_content('ゴミ箱')
        expect(page).to have_content('INBOX.Trash')
        expect(current_path).to eq index_path

        # new
        click_link I18n.t('ss.links.new')
        within "form#item-form" do
          fill_in "item[name]", with: item_title
          click_button I18n.t('ss.buttons.save')
        end
        wait_for_notice I18n.t("ss.notice.saved")
        expect(page).to have_content(item_title)
        expect(current_path).to eq index_path

        # edit
        click_link item_title
        click_link I18n.t('ss.links.edit')
        within "form#item-form" do
          fill_in "item[name]", with: "#{item_title}2"
          click_button I18n.t('ss.buttons.save')
        end
        wait_for_notice I18n.t("ss.notice.saved")
        expect(page).to have_content("#{item_title}2")

        # delete
        click_link item_title
        click_link I18n.t('ss.links.delete')
        within "form#item-form" do
          click_button I18n.t('ss.buttons.delete')
        end
        wait_for_notice I18n.t("ss.notice.deleted")

        # reload
        click_link I18n.t('webmail.links.reload_mailboxes')
        expect(page).to have_css(".main-box", text: I18n.t('webmail.links.reload_mailboxes'))
        expect(page).to have_no_content('INBOX')
        expect(page).to have_no_content(item_title)
        within "form" do
          click_button I18n.t('webmail.buttons.sync')
        end
        wait_for_notice I18n.t("webmail.notice.reloaded_mailboxes")

        expect(current_path).to eq index_path
      end
    end
  end

  describe "webmail_mode is account" do
    let(:index_path) { webmail_mailboxes_path(account: 0) }

    it_behaves_like 'webmail mailboxes flow'
  end

  describe "webmail_mode is group" do
    let(:group) { create :webmail_group }
    let(:index_path) { webmail_mailboxes_path(account: "#{group.id}.0", webmail_mode: :group) }

    before { user.add_to_set(group_ids: [ group.id ]) }

    it_behaves_like 'webmail mailboxes flow'
  end
end
