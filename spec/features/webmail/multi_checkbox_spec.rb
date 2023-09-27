require 'spec_helper'
Selenium::WebDriver.logger
describe 'webmail_multi_heckbox', type: :feature, dbscope: :example, imap: true, js: true do
  context 'webメール' do
    let(:user) { webmail_imap }
    let(:item_subject) { "subject-#{unique_id}" }
    let(:item_texts) { Array.new(rand(1..10)) { "message-#{unique_id}" } }
    let!(:index_path) { webmail_mails_path(account: 0) }

    before do
      ActionMailer::Base.deliveries.clear
      login_user(user)
    end
    after do
      ActionMailer::Base.deliveries.clear
    end

    context "個人アドレス" do
      let!(:address_group1) { create :webmail_address_group, cur_user: user, order: 10 }
      let!(:address_group2) { create :webmail_address_group, cur_user: user, order: 20 }
      let!(:address1) do
        create :webmail_address, cur_user: user, address_group: address_group1, member: user
      end
      let!(:address2) do
        create :webmail_address, cur_user: user, address_group: address_group2, member: user
      end
      it '個人' do
        visit index_path
        wait_for_js_ready
        new_window = window_opened_by { click_on I18n.t('ss.links.new') }
        within_window new_window do
          within "form#item-form" do
            click_on I18n.t("webmail.links.show_cc_bcc")
            within 'dl.see.all' do
              wait_cbox_open { click_on I18n.t('mongoid.models.webmail/address') }
            end
          end
          wait_for_cbox do
            check "to_ids#{address1.id}"
            check "cc_ids#{address1.id}"
            check "bcc_ids#{address1.id}"
            click_on I18n.t('ss.links.select')
          end
          within 'form#item-form' do
            take_full_page_screenshot("kojin_selected.png")
            within '.webmail-mail-form-address.to' do
              expect(page).to have_content(address1.name)
            end
            within '.webmail-mail-form-address.cc-bcc.cc' do
              expect(page).to have_content(address1.name)
            end
            within '.webmail-mail-form-address.cc-bcc.bcc' do
              expect(page).to have_content(address1.name)
            end
            fill_in 'item[subject]', with: subject
            fill_in 'item[text]', with: text
            click_on I18n.t('ss.buttons.send')
          end
        end
        wait_for_notice I18n.t('ss.notice.sent')

        visit gws_memo_messages_path(site: user.root_groups.first, folder: 'INBOX.Sent')
      end

      it '全選択' do
        visit index_path
        wait_for_js_ready
        new_window = window_opened_by { click_on I18n.t('ss.links.new') }
        within_window new_window do
          within "form#item-form" do
            click_on I18n.t("webmail.links.show_cc_bcc")
            within 'dl.see.all' do
              wait_cbox_open { click_on I18n.t('mongoid.models.webmail/address') }
            end
          end
          wait_for_cbox do
            check "to_all"
            check "cc_all"
            check "bcc_all"
            click_on I18n.t('ss.links.select')
          end
          within 'form#item-form' do
            within '.webmail-mail-form-address.to' do
              expect(page).to have_content(address1.name)
              expect(page).to have_content(address2.name)
            end
            within '.webmail-mail-form-address.cc-bcc.cc' do
              expect(page).to have_content(address1.name)
              expect(page).to have_content(address2.name)
            end
            within '.webmail-mail-form-address.cc-bcc.bcc' do
              expect(page).to have_content(address1.name)
              expect(page).to have_content(address2.name)
            end
            fill_in 'item[subject]', with: subject
            fill_in 'item[text]', with: text
            click_on I18n.t('ss.buttons.send')
          end
        end
        wait_for_notice I18n.t('ss.notice.sent')
      end
    end

    context "組織アドレス" do
      let(:user1) { webmail_imap }
      let(:user2) { webmail_imap }
      it '個人' do
        visit index_path
        wait_for_js_ready
        new_window = window_opened_by { click_on I18n.t('ss.links.new') }
        within_window new_window do
          within "form#item-form" do
            click_on I18n.t("webmail.links.show_cc_bcc")
            within 'dl.see.all' do
              wait_cbox_open { click_on I18n.t('gws.organization_addresses') }
            end
          end
          wait_for_cbox do
            check "to_ids#{user1.id}"
            check "cc_ids#{user1.id}"
            check "bcc_ids#{user1.id}"
            click_on I18n.t('ss.links.select')
          end
          within 'form#item-form' do
            within '.webmail-mail-form-address.to' do
              expect(page).to have_content(user1.name)
            end
            within '.webmail-mail-form-address.cc-bcc.cc' do
              expect(page).to have_content(user1.name)
            end
            within '.webmail-mail-form-address.cc-bcc.bcc' do
              expect(page).to have_content(user1.name)
            end
            fill_in 'item[subject]', with: subject
            fill_in 'item[text]', with: text
            click_on I18n.t('ss.buttons.send')
          end
        end
        wait_for_notice I18n.t('ss.notice.sent')
      end

      it '全選択' do
        visit index_path
        wait_for_js_ready
        new_window = window_opened_by { click_on I18n.t('ss.links.new') }
        within_window new_window do
          within "form#item-form" do
            click_on I18n.t("webmail.links.show_cc_bcc")
            within 'dl.see.all' do
              wait_cbox_open { click_on I18n.t('gws.organization_addresses') }
            end
          end
          wait_for_cbox do
            check "to_all"
            check "cc_all"
            check "bcc_all"
            click_on I18n.t('ss.links.select')
          end
          within 'form#item-form' do
            within '.webmail-mail-form-address.to' do
              expect(page).to have_content(user1.name)
              expect(page).to have_content(user2.name)
            end
            within '.webmail-mail-form-address.cc-bcc.cc' do
              expect(page).to have_content(user1.name)
              expect(page).to have_content(user2.name)
            end
            within '.webmail-mail-form-address.cc-bcc.bcc' do
              expect(page).to have_content(user1.name)
              expect(page).to have_content(user2.name)
            end
            fill_in 'item[subject]', with: subject
            fill_in 'item[text]', with: text
            click_on I18n.t('ss.buttons.send')
          end
        end
        wait_for_notice I18n.t('ss.notice.sent')
      end
    end

    context "共有アドレス" do
      before { login_gws_user }
      let(:site) { gws_site }
      let(:user) { gws_user }
      let!(:group1) { create(:gws_shared_address_group, cur_site: site, cur_user: gws_user) }
      let!(:group2) { create(:gws_shared_address_group, cur_site: site, cur_user: gws_user) }
      let!(:address1) do
        create(:gws_shared_address_address, cur_site: site, cur_user: gws_user, address_group_id: group1.id, member_id: gws_user.id)
      end
      let!(:address2) do
        create(:gws_shared_address_address, cur_site: site, cur_user: gws_user, address_group_id: group2.id, member_id: gws_user.id)
      end
      it '個人' do
        visit index_path
        wait_for_js_ready
        new_window = window_opened_by { click_on I18n.t("ss.links.new") }
        within_window new_window do
          within "form#item-form" do
            click_on I18n.t("webmail.links.show_cc_bcc")
            within 'dl.see.all' do
              wait_cbox_open { click_on I18n.t('modules.gws/shared_address') }
            end
          end
          wait_for_cbox do
            check "to_ids#{address1.id}"
            check "cc_ids#{address1.id}"
            check "bcc_ids#{address1.id}"
            click_on I18n.t('ss.links.select')
          end
          within 'form#item-form' do
            within '.webmail-mail-form-address.to' do
              expect(page).to have_content(address1.name)
            end
            within '.webmail-mail-form-address.cc-bcc.cc' do
              expect(page).to have_content(address1.name)
            end
            within '.webmail-mail-form-address.cc-bcc.bcc' do
              expect(page).to have_content(address1.name)
            end
            fill_in 'item[subject]', with: subject
            fill_in 'item[text]', with: text
            click_on I18n.t('ss.buttons.send')
          end
        end
        wait_for_notice I18n.t('ss.notice.sent')
      end

      it '全選択' do
        visit index_path
        wait_for_js_ready
        new_window = window_opened_by { click_on I18n.t('ss.links.new') }
        within_window new_window do
          within "form#item-form" do
            click_on I18n.t("webmail.links.show_cc_bcc")
            within 'dl.see.all' do
              wait_cbox_open { click_on I18n.t('modules.gws/shared_address') }
            end
          end
          wait_for_cbox do
            check "to_all"
            check "cc_all"
            check "bcc_all"
            click_on I18n.t('ss.links.select')
          end
          within 'form#item-form' do
            within '.webmail-mail-form-address.to' do
              expect(page).to have_content(address1.name)
              expect(page).to have_content(address2.name)
            end
            within '.webmail-mail-form-address.cc-bcc.cc' do
              expect(page).to have_content(address1.name)
              expect(page).to have_content(address2.name)
            end
            within '.webmail-mail-form-address.cc-bcc.bcc' do
              expect(page).to have_content(address1.name)
              expect(page).to have_content(address2.name)
            end
            fill_in 'item[subject]', with: subject
            fill_in 'item[text]', with: text
            click_on I18n.t('ss.buttons.send')
          end
        end
        wait_for_notice I18n.t('ss.notice.sent')
      end
    end
  end
end