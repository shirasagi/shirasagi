require 'spec_helper'

describe 'webmail_multi_heckbox', type: :feature, dbscope: :example, imap: true, js: true do
  let!(:user) { webmail_imap }
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
    let!(:address_group3) { create :webmail_address_group, cur_user: user, order: 30 }
    let!(:address1) do
      create :webmail_address, cur_user: user, address_group: address_group1
    end
    let!(:address2) do
      create :webmail_address, cur_user: user, address_group: address_group2
    end
    let!(:address3) do
      create :webmail_address, cur_user: user, address_group: address_group3
    end

    context '個人' do
      it do
        visit index_path
        wait_for_js_ready
        new_window = window_opened_by { click_on I18n.t('ss.links.new') }
        within_window new_window do
          within "form#item-form" do
            click_on I18n.t("webmail.links.show_cc_bcc")
            within 'dl.see.all' do
              wait_for_cbox_opened { click_on I18n.t('mongoid.models.webmail/address') }
            end
          end
          within_cbox do
            check "to_ids#{address1.id}"
            check "cc_ids#{address2.id}"
            check "bcc_ids#{address3.id}"
            wait_for_cbox_closed { click_on I18n.t('ss.links.select') }
          end
          within 'form#item-form' do
            within '.webmail-mail-form-address.to' do
              expect(page).to have_content(address1.name)
            end
            within '.webmail-mail-form-address.cc-bcc.cc' do
              expect(page).to have_content(address2.name)
            end
            within '.webmail-mail-form-address.cc-bcc.bcc' do
              expect(page).to have_content(address3.name)
            end
            fill_in 'item[subject]', with: item_subject
            fill_in 'item[text]', with: item_texts.join("\n")
            click_on I18n.t('ss.buttons.send')
          end
        end
        wait_for_notice I18n.t('ss.notice.sent')

        expect(ActionMailer::Base.deliveries.length).to eq 1
        ActionMailer::Base.deliveries.first.tap do |mail|
          expect(mail.subject).to eq item_subject
          expect(mail.from.first).to eq user.email
          mail.to.map(&:to_s).tap do |addresses|
            expect(addresses).to have(1).items
            expect(addresses).to include(address1.email)
          end
          mail.cc.map(&:to_s).tap do |addresses|
            expect(addresses).to have(1).items
            expect(addresses).to include(address2.email)
          end
          mail.bcc.map(&:to_s).tap do |addresses|
            expect(addresses).to have(1).items
            expect(addresses).to include(address3.email)
          end
          expect(mail.body.multipart?).to be_falsey
          expect(mail.body.raw_source).to include(item_texts.join("\r\n"))
        end
      end
    end

    context '全選択' do
      it do
        visit index_path
        wait_for_js_ready
        new_window = window_opened_by { click_on I18n.t('ss.links.new') }
        within_window new_window do
          within "form#item-form" do
            click_on I18n.t("webmail.links.show_cc_bcc")
            within 'dl.see.all' do
              wait_for_cbox_opened { click_on I18n.t('mongoid.models.webmail/address') }
            end
          end
          within_cbox do
            check "to_all"
            check "cc_all"
            check "bcc_all"
            wait_for_cbox_closed { click_on I18n.t('ss.links.select') }
          end
          within 'form#item-form' do
            within '.webmail-mail-form-address.to' do
              expect(page).to have_content(address1.name)
              expect(page).to have_content(address2.name)
              expect(page).to have_content(address3.name)
            end
            within '.webmail-mail-form-address.cc-bcc.cc' do
              expect(page).to have_content(address1.name)
              expect(page).to have_content(address2.name)
              expect(page).to have_content(address3.name)
            end
            within '.webmail-mail-form-address.cc-bcc.bcc' do
              expect(page).to have_content(address1.name)
              expect(page).to have_content(address2.name)
              expect(page).to have_content(address3.name)
            end
            fill_in 'item[subject]', with: item_subject
            fill_in 'item[text]', with: item_texts.join("\n")
            click_on I18n.t('ss.buttons.send')
          end
        end
        wait_for_notice I18n.t('ss.notice.sent')

        expect(ActionMailer::Base.deliveries.length).to eq 1
        ActionMailer::Base.deliveries.first.tap do |mail|
          expect(mail.subject).to eq item_subject
          expect(mail.from.first).to eq user.email
          mail.to.map(&:to_s).tap do |addresses|
            expect(addresses).to have(3).items
            expect(addresses).to include(address1.email, address2.email, address3.email)
          end
          mail.cc.map(&:to_s).tap do |addresses|
            expect(addresses).to have(3).items
            expect(addresses).to include(address1.email, address2.email, address3.email)
          end
          mail.bcc.map(&:to_s).tap do |addresses|
            expect(addresses).to have(3).items
            expect(addresses).to include(address1.email, address2.email, address3.email)
          end
          expect(mail.body.multipart?).to be_falsey
          expect(mail.body.raw_source).to include(item_texts.join("\r\n"))
        end
      end
    end

    context '名称クリック' do
      it do
        visit index_path
        wait_for_js_ready
        new_window = window_opened_by { click_on I18n.t('ss.links.new') }
        within_window new_window do
          within "form#item-form" do
            click_on I18n.t("webmail.links.show_cc_bcc")
            within 'dl.see.all' do
              wait_for_cbox_opened { click_on I18n.t('mongoid.models.webmail/address') }
            end
          end
          within_cbox do
            wait_for_cbox_closed { click_on address1.name }
          end
          within 'form#item-form' do
            within '.webmail-mail-form-address.to' do
              expect(page).to have_content(address1.name)
            end
            fill_in 'item[subject]', with: item_subject
            fill_in 'item[text]', with: item_texts.join("\n")
            click_on I18n.t('ss.buttons.send')
          end
        end
        wait_for_notice I18n.t('ss.notice.sent')

        expect(ActionMailer::Base.deliveries.length).to eq 1
        ActionMailer::Base.deliveries.first.tap do |mail|
          expect(mail.subject).to eq item_subject
          expect(mail.from.first).to eq user.email
          mail.to.map(&:to_s).tap do |addresses|
            expect(addresses).to have(1).items
            expect(addresses).to include(address1.email)
          end
          expect(mail.body.multipart?).to be_falsey
          expect(mail.body.raw_source).to include(item_texts.join("\r\n"))
        end
      end
    end
  end

  context "組織アドレス" do
    let!(:user1) { create :webmail_user_without_imap, group_ids: user.group_ids }
    let!(:user2) { create :webmail_user_without_imap, group_ids: user.group_ids }
    let!(:user3) { create :webmail_user_without_imap, group_ids: user.group_ids }

    context '個人' do
      it do
        visit index_path
        wait_for_js_ready
        new_window = window_opened_by { click_on I18n.t('ss.links.new') }
        within_window new_window do
          within "form#item-form" do
            click_on I18n.t("webmail.links.show_cc_bcc")
            within 'dl.see.all' do
              wait_for_cbox_opened { click_on I18n.t('gws.organization_addresses') }
            end
          end
          within_cbox do
            check "to_ids#{user1.id}"
            check "cc_ids#{user2.id}"
            check "bcc_ids#{user3.id}"
            wait_for_cbox_closed { click_on I18n.t('ss.links.select') }
          end
          within 'form#item-form' do
            within '.webmail-mail-form-address.to' do
              expect(page).to have_content(user1.name)
            end
            within '.webmail-mail-form-address.cc-bcc.cc' do
              expect(page).to have_content(user2.name)
            end
            within '.webmail-mail-form-address.cc-bcc.bcc' do
              expect(page).to have_content(user3.name)
            end
            fill_in 'item[subject]', with: item_subject
            fill_in 'item[text]', with: item_texts.join("\n")
            click_on I18n.t('ss.buttons.send')
          end
        end
        wait_for_notice I18n.t('ss.notice.sent')

        expect(ActionMailer::Base.deliveries.length).to eq 1
        ActionMailer::Base.deliveries.first.tap do |mail|
          expect(mail.subject).to eq item_subject
          expect(mail.from.first).to eq user.email
          mail.to.map(&:to_s).tap do |addresses|
            expect(addresses).to have(1).items
            expect(addresses).to include(user1.email)
          end
          mail.cc.map(&:to_s).tap do |addresses|
            expect(addresses).to have(1).items
            expect(addresses).to include(user2.email)
          end
          mail.bcc.map(&:to_s).tap do |addresses|
            expect(addresses).to have(1).items
            expect(addresses).to include(user3.email)
          end
          expect(mail.body.multipart?).to be_falsey
          expect(mail.body.raw_source).to include(item_texts.join("\r\n"))
        end
      end
    end

    context '全選択' do
      it do
        visit index_path
        wait_for_js_ready
        new_window = window_opened_by { click_on I18n.t('ss.links.new') }
        within_window new_window do
          within "form#item-form" do
            click_on I18n.t("webmail.links.show_cc_bcc")
            within 'dl.see.all' do
              wait_for_cbox_opened { click_on I18n.t('gws.organization_addresses') }
            end
          end
          within_cbox do
            check "to_all"
            check "cc_all"
            check "bcc_all"
            wait_for_cbox_closed { click_on I18n.t('ss.links.select') }
          end
          within 'form#item-form' do
            within '.webmail-mail-form-address.to' do
              expect(page).to have_content(user1.name)
              expect(page).to have_content(user2.name)
              expect(page).to have_content(user3.name)
            end
            within '.webmail-mail-form-address.cc-bcc.cc' do
              expect(page).to have_content(user1.name)
              expect(page).to have_content(user2.name)
              expect(page).to have_content(user3.name)
            end
            within '.webmail-mail-form-address.cc-bcc.bcc' do
              expect(page).to have_content(user1.name)
              expect(page).to have_content(user2.name)
              expect(page).to have_content(user3.name)
            end
            fill_in 'item[subject]', with: item_subject
            fill_in 'item[text]', with: item_texts.join("\n")
            click_on I18n.t('ss.buttons.send')
          end
        end
        wait_for_notice I18n.t('ss.notice.sent')

        expect(ActionMailer::Base.deliveries.length).to eq 1
        ActionMailer::Base.deliveries.first.tap do |mail|
          expect(mail.subject).to eq item_subject
          expect(mail.from.first).to eq user.email
          mail.to.map(&:to_s).tap do |addresses|
            expect(addresses).to have_at_least(3).items
            expect(addresses).to include(user1.email, user2.email, user3.email)
          end
          mail.cc.map(&:to_s).tap do |addresses|
            expect(addresses).to have_at_least(3).items
            expect(addresses).to include(user1.email, user2.email, user3.email)
          end
          mail.bcc.map(&:to_s).tap do |addresses|
            expect(addresses).to have_at_least(3).items
            expect(addresses).to include(user1.email, user2.email, user3.email)
          end
          expect(mail.body.multipart?).to be_falsey
          expect(mail.body.raw_source).to include(item_texts.join("\r\n"))
        end
      end
    end

    context '名称クリック' do
      it do
        visit index_path
        wait_for_js_ready
        new_window = window_opened_by { click_on I18n.t('ss.links.new') }
        within_window new_window do
          within "form#item-form" do
            click_on I18n.t("webmail.links.show_cc_bcc")
            within 'dl.see.all' do
              wait_for_cbox_opened { click_on I18n.t('gws.organization_addresses') }
            end
          end
          within_cbox do
            wait_for_cbox_closed { click_on user1.name }
          end
          within 'form#item-form' do
            within '.webmail-mail-form-address.to' do
              expect(page).to have_content(user1.name)
            end
            fill_in 'item[subject]', with: item_subject
            fill_in 'item[text]', with: item_texts.join("\n")
            click_on I18n.t('ss.buttons.send')
          end
        end
        wait_for_notice I18n.t('ss.notice.sent')

        expect(ActionMailer::Base.deliveries.length).to eq 1
        ActionMailer::Base.deliveries.first.tap do |mail|
          expect(mail.subject).to eq item_subject
          expect(mail.from.first).to eq user.email
          mail.to.map(&:to_s).tap do |addresses|
            expect(addresses).to have(1).items
            expect(addresses).to include(user1.email)
          end
          expect(mail.body.multipart?).to be_falsey
          expect(mail.body.raw_source).to include(item_texts.join("\r\n"))
        end
      end
    end
  end

  context "共有アドレス" do
    let!(:group1) { create(:gws_shared_address_group, cur_site: gws_site, cur_user: gws_user) }
    let!(:group2) { create(:gws_shared_address_group, cur_site: gws_site, cur_user: gws_user) }
    let!(:group3) { create(:gws_shared_address_group, cur_site: gws_site, cur_user: gws_user) }
    let!(:address1) do
      create(:gws_shared_address_address, cur_site: gws_site, cur_user: gws_user, address_group_id: group1.id)
    end
    let!(:address2) do
      create(:gws_shared_address_address, cur_site: gws_site, cur_user: gws_user, address_group_id: group2.id)
    end
    let!(:address3) do
      create(:gws_shared_address_address, cur_site: gws_site, cur_user: gws_user, address_group_id: group2.id)
    end

    context '個人' do
      it do
        visit index_path
        wait_for_js_ready
        new_window = window_opened_by { click_on I18n.t("ss.links.new") }
        within_window new_window do
          within "form#item-form" do
            click_on I18n.t("webmail.links.show_cc_bcc")
            within 'dl.see.all' do
              wait_for_cbox_opened { click_on I18n.t('modules.gws/shared_address') }
            end
          end
          within_cbox do
            check "to_ids#{address1.id}"
            check "cc_ids#{address2.id}"
            check "bcc_ids#{address3.id}"
            wait_for_cbox_closed { click_on I18n.t('ss.links.select') }
          end
          within 'form#item-form' do
            within '.webmail-mail-form-address.to' do
              expect(page).to have_content(address1.name)
            end
            within '.webmail-mail-form-address.cc-bcc.cc' do
              expect(page).to have_content(address2.name)
            end
            within '.webmail-mail-form-address.cc-bcc.bcc' do
              expect(page).to have_content(address3.name)
            end
            fill_in 'item[subject]', with: item_subject
            fill_in 'item[text]', with: item_texts.join("\n")
            click_on I18n.t('ss.buttons.send')
          end
        end
        wait_for_notice I18n.t('ss.notice.sent')

        expect(ActionMailer::Base.deliveries.length).to eq 1
        ActionMailer::Base.deliveries.first.tap do |mail|
          expect(mail.subject).to eq item_subject
          expect(mail.from.first).to eq user.email
          mail.to.map(&:to_s).tap do |addresses|
            expect(addresses).to have(1).items
            expect(addresses).to include(address1.email)
          end
          mail.cc.map(&:to_s).tap do |addresses|
            expect(addresses).to have(1).items
            expect(addresses).to include(address2.email)
          end
          mail.bcc.map(&:to_s).tap do |addresses|
            expect(addresses).to have(1).items
            expect(addresses).to include(address3.email)
          end
          expect(mail.body.multipart?).to be_falsey
          expect(mail.body.raw_source).to include(item_texts.join("\r\n"))
        end
      end
    end

    context '全選択' do
      it do
        visit index_path
        wait_for_js_ready
        new_window = window_opened_by { click_on I18n.t('ss.links.new') }
        within_window new_window do
          within "form#item-form" do
            click_on I18n.t("webmail.links.show_cc_bcc")
            within 'dl.see.all' do
              wait_for_cbox_opened { click_on I18n.t('modules.gws/shared_address') }
            end
          end
          within_cbox do
            check "to_all"
            check "cc_all"
            check "bcc_all"
            wait_for_cbox_closed { click_on I18n.t('ss.links.select') }
          end
          within 'form#item-form' do
            within '.webmail-mail-form-address.to' do
              expect(page).to have_content(address1.name)
              expect(page).to have_content(address2.name)
              expect(page).to have_content(address3.name)
            end
            within '.webmail-mail-form-address.cc-bcc.cc' do
              expect(page).to have_content(address1.name)
              expect(page).to have_content(address2.name)
              expect(page).to have_content(address3.name)
            end
            within '.webmail-mail-form-address.cc-bcc.bcc' do
              expect(page).to have_content(address1.name)
              expect(page).to have_content(address2.name)
              expect(page).to have_content(address3.name)
            end
            fill_in 'item[subject]', with: item_subject
            fill_in 'item[text]', with: item_texts.join("\n")
            click_on I18n.t('ss.buttons.send')
          end
        end
        wait_for_notice I18n.t('ss.notice.sent')

        expect(ActionMailer::Base.deliveries.length).to eq 1
        ActionMailer::Base.deliveries.first.tap do |mail|
          expect(mail.subject).to eq item_subject
          expect(mail.from.first).to eq user.email
          mail.to.map(&:to_s).tap do |addresses|
            expect(addresses).to have(3).items
            expect(addresses).to include(address1.email, address2.email, address3.email)
          end
          mail.cc.map(&:to_s).tap do |addresses|
            expect(addresses).to have(3).items
            expect(addresses).to include(address1.email, address2.email, address3.email)
          end
          mail.bcc.map(&:to_s).tap do |addresses|
            expect(addresses).to have(3).items
            expect(addresses).to include(address1.email, address2.email, address3.email)
          end
          expect(mail.body.multipart?).to be_falsey
          expect(mail.body.raw_source).to include(item_texts.join("\r\n"))
        end
      end
    end

    context '名称クリック' do
      it do
        visit index_path
        wait_for_js_ready
        new_window = window_opened_by { click_on I18n.t("ss.links.new") }
        within_window new_window do
          within "form#item-form" do
            click_on I18n.t("webmail.links.show_cc_bcc")
            within 'dl.see.all' do
              wait_for_cbox_opened { click_on I18n.t('modules.gws/shared_address') }
            end
          end
          within_cbox do
            wait_for_cbox_closed { click_on address1.name }
          end
          within 'form#item-form' do
            within '.webmail-mail-form-address.to' do
              expect(page).to have_content(address1.name)
            end
            fill_in 'item[subject]', with: item_subject
            fill_in 'item[text]', with: item_texts.join("\n")
            click_on I18n.t('ss.buttons.send')
          end
        end
        wait_for_notice I18n.t('ss.notice.sent')

        expect(ActionMailer::Base.deliveries.length).to eq 1
        ActionMailer::Base.deliveries.first.tap do |mail|
          expect(mail.subject).to eq item_subject
          expect(mail.from.first).to eq user.email
          mail.to.map(&:to_s).tap do |addresses|
            expect(addresses).to have(1).items
            expect(addresses).to include(address1.email)
          end
          expect(mail.body.multipart?).to be_falsey
          expect(mail.body.raw_source).to include(item_texts.join("\r\n"))
        end
      end
    end
  end
end
