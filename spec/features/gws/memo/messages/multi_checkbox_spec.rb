require 'spec_helper'

describe 'gws_memo_messages', type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:user) { gws_user }
  let!(:sys_user) { gws_sys_user }
  let!(:user1) { create(:gws_user, cur_site: site, group_ids: user.group_ids, gws_role_ids: user.gws_role_ids) }
  let!(:user2) { create(:gws_user, cur_site: site, group_ids: user.group_ids, gws_role_ids: user.gws_role_ids) }
  let!(:user3) { create(:gws_user, cur_site: site, group_ids: user.group_ids, gws_role_ids: user.gws_role_ids) }
  let(:subject) { "subject-#{unique_id}" }
  let(:text) { Array.new(3) { "text-#{unique_id}" } }

  before { login_user user }

  context '組織アドレス' do
    context '個人' do
      it do
        visit gws_memo_messages_path(site)
        click_on I18n.t('ss.links.new')

        within 'form#item-form' do
          click_on I18n.t("webmail.links.show_cc_bcc")
          within 'dl.see.all' do
            wait_for_cbox_opened { click_on I18n.t('gws.organization_addresses') }
          end
        end
        within_cbox do
          check "to_ids#{user1.id}"
          check "cc_ids#{user2.id}"
          check "bcc_ids#{user3.id}"
          wait_cbox_close { click_on I18n.t('ss.links.select') }
        end
        within 'form#item-form' do
          within 'dl.see.to' do
            expect(page).to have_css(".index", text: user1.name)
          end
          within 'dl.see.cc' do
            expect(page).to have_css(".index", text: user2.name)
          end
          within 'dl.see.bcc' do
            expect(page).to have_css(".index", text: user3.name)
          end
          fill_in 'item[subject]', with: subject
          fill_in 'item[text]', with: text.join("\n")
          accept_confirm do
            click_on I18n.t('gws/memo/message.commit_params_check')
          end
        end
        wait_for_notice I18n.t("ss.notice.sent")

        expect(Gws::Memo::Message.all.count).to eq 1
        Gws::Memo::Message.all.first.tap do |message|
          expect(message.subject).to eq subject
          expect(message.text).to eq text.join("\r\n")
          expect(message.user_settings).to include({ 'user_id' => user1.id, 'path' => 'INBOX' })
          expect(message.user_settings).to include({ 'user_id' => user2.id, 'path' => 'INBOX' })
          expect(message.user_settings).to include({ 'user_id' => user3.id, 'path' => 'INBOX' })
          expect(message.to_member_name).to eq user1.long_name
          expect(message.from_member_name).to eq user.long_name
          expect(message.to_member_ids).to eq [ user1.id ]
          expect(message.cc_member_ids).to eq [ user2.id ]
          expect(message.bcc_member_ids).to eq [ user3.id ]
          expect(message.to_webmail_address_group_ids).to be_blank
          expect(message.cc_webmail_address_group_ids).to be_blank
          expect(message.bcc_webmail_address_group_ids).to be_blank
          expect(message.to_shared_address_group_ids).to be_blank
          expect(message.cc_shared_address_group_ids).to be_blank
          expect(message.bcc_shared_address_group_ids).to be_blank
        end
      end
    end

    context '全選択' do
      it do
        visit gws_memo_messages_path(site)
        click_on I18n.t('ss.links.new')

        within 'form#item-form' do
          click_on I18n.t("webmail.links.show_cc_bcc")
          within 'dl.see.all' do
            wait_for_cbox_opened { click_on I18n.t('gws.organization_addresses') }
          end
        end
        within_cbox do
          check "to_all"
          check "cc_all"
          check "bcc_all"
          within ".search-ui-select" do
            wait_cbox_close { click_on I18n.t('ss.links.select') }
          end
        end
        within 'form#item-form' do
          within 'dl.see.to' do
            expect(page).to have_css(".index", text: user1.name)
            expect(page).to have_css(".index", text: user2.name)
            expect(page).to have_css(".index", text: user3.name)
          end
          within 'dl.see.cc' do
            expect(page).to have_css(".index", text: user1.name)
            expect(page).to have_css(".index", text: user2.name)
            expect(page).to have_css(".index", text: user3.name)
          end
          within 'dl.see.bcc' do
            expect(page).to have_css(".index", text: user1.name)
            expect(page).to have_css(".index", text: user2.name)
            expect(page).to have_css(".index", text: user3.name)
          end
          fill_in 'item[subject]', with: subject
          fill_in 'item[text]', with: text.join("\n")
          page.accept_confirm do
            click_on I18n.t("ss.buttons.send")
          end
        end
        wait_for_notice I18n.t("ss.notice.sent")

        expect(Gws::Memo::Message.all.count).to eq 1
        Gws::Memo::Message.all.first.tap do |message|
          expect(message.subject).to eq subject
          expect(message.text).to eq text.join("\r\n")
          expect(message.user_settings).to include({ 'user_id' => user1.id, 'path' => 'INBOX' })
          expect(message.user_settings).to include({ 'user_id' => user2.id, 'path' => 'INBOX' })
          expect(message.user_settings).to include({ 'user_id' => user3.id, 'path' => 'INBOX' })
          expect(message.to_member_name).to include(user1.long_name, user2.long_name, user3.long_name)
          expect(message.from_member_name).to eq user.long_name
          expect(message.to_member_ids).to have(5).items
          expect(message.to_member_ids).to include(user1.id, user2.id, user3.id, user.id, sys_user.id)
          expect(message.cc_member_ids).to have(5).items
          expect(message.cc_member_ids).to include(user1.id, user2.id, user3.id, user.id, sys_user.id)
          expect(message.bcc_member_ids).to have(5).items
          expect(message.bcc_member_ids).to include(user1.id, user2.id, user3.id, user.id, sys_user.id)
          expect(message.to_webmail_address_group_ids).to be_blank
          expect(message.cc_webmail_address_group_ids).to be_blank
          expect(message.bcc_webmail_address_group_ids).to be_blank
          expect(message.to_shared_address_group_ids).to be_blank
          expect(message.cc_shared_address_group_ids).to be_blank
          expect(message.bcc_shared_address_group_ids).to be_blank
        end
      end
    end
  end

  context '共有アドレス' do
    let!(:group1) { create(:gws_shared_address_group, cur_site: site, cur_user: user) }
    let!(:group2) { create(:gws_shared_address_group, cur_site: site, cur_user: user) }
    let!(:group3) { create(:gws_shared_address_group, cur_site: site, cur_user: user) }
    let!(:address1) do
      create(:gws_shared_address_address, cur_site: site, cur_user: user, address_group_id: group1.id, member_id: user1.id)
    end
    let!(:address2) do
      create(:gws_shared_address_address, cur_site: site, cur_user: user, address_group_id: group2.id, member_id: user2.id)
    end
    let!(:address3) do
      create(:gws_shared_address_address, cur_site: site, cur_user: user, address_group_id: group3.id, member_id: user3.id)
    end

    context "個人" do
      it do
        visit gws_memo_messages_path(site)
        click_on I18n.t('ss.links.new')
        click_on I18n.t("webmail.links.show_cc_bcc")
        within 'form#item-form' do
          within 'dl.see.all' do
            wait_for_cbox_opened { click_on I18n.t('modules.gws/shared_address') }
          end
        end
        within_cbox do
          check "to_ids#{address1.id}"
          check "cc_ids#{address2.id}"
          check "bcc_ids#{address3.id}"
          wait_cbox_close { click_on I18n.t('ss.links.select') }
        end
        within 'form#item-form' do
          within 'dl.see.to' do
            expect(page).to have_css(".index", text: user1.long_name)
          end
          within 'dl.see.cc' do
            expect(page).to have_css(".index", text: user2.long_name)
          end
          within 'dl.see.bcc' do
            expect(page).to have_css(".index", text: user3.long_name)
          end
          fill_in 'item[subject]', with: subject
          fill_in 'item[text]', with: text.join("\n")
          page.accept_confirm do
            click_on I18n.t('ss.buttons.send')
          end
        end
        wait_for_notice I18n.t('ss.notice.sent')

        expect(Gws::Memo::Message.all.count).to eq 1
        Gws::Memo::Message.all.first.tap do |message|
          expect(message.subject).to eq subject
          expect(message.text).to eq text.join("\r\n")
          expect(message.user_settings).to include({ 'user_id' => user1.id, 'path' => 'INBOX' })
          expect(message.user_settings).to include({ 'user_id' => user2.id, 'path' => 'INBOX' })
          expect(message.user_settings).to include({ 'user_id' => user3.id, 'path' => 'INBOX' })
          expect(message.to_member_name).to eq user1.long_name
          expect(message.from_member_name).to eq user.long_name
          expect(message.to_member_ids).to eq [ user1.id ]
          expect(message.cc_member_ids).to eq [ user2.id ]
          expect(message.bcc_member_ids).to eq [ user3.id ]
          expect(message.to_webmail_address_group_ids).to be_blank
          expect(message.cc_webmail_address_group_ids).to be_blank
          expect(message.bcc_webmail_address_group_ids).to be_blank
          expect(message.to_shared_address_group_ids).to be_blank
          expect(message.cc_shared_address_group_ids).to be_blank
          expect(message.bcc_shared_address_group_ids).to be_blank
        end
      end
    end

    context "グループ" do
      it do
        visit gws_memo_messages_path(site)
        click_on I18n.t('ss.links.new')
        click_on I18n.t("webmail.links.show_cc_bcc")
        within 'form#item-form' do
          within 'dl.see.all' do
            wait_for_cbox_opened { click_on I18n.t('modules.gws/shared_address') }
          end
        end
        within_cbox do
          click_on I18n.t('mongoid.models.gws/shared_address/group')
          check "to_ids#{group1.id}"
          check "cc_ids#{group2.id}"
          check "bcc_ids#{group3.id}"
          wait_cbox_close { click_on I18n.t('ss.links.select') }
        end
        within 'form#item-form' do
          within 'dl.see.to' do
            expect(page).to have_css(".index", text: group1.name)
          end
          within 'dl.see.cc' do
            expect(page).to have_css(".index", text: group2.name)
          end
          within 'dl.see.bcc' do
            expect(page).to have_css(".index", text: group3.name)
          end
          fill_in 'item[subject]', with: subject
          fill_in 'item[text]', with: text.join("\n")
          page.accept_confirm do
            click_on I18n.t('ss.buttons.send')
          end
        end
        wait_for_notice I18n.t('ss.notice.sent')

        expect(Gws::Memo::Message.all.count).to eq 1
        Gws::Memo::Message.all.first.tap do |message|
          expect(message.subject).to eq subject
          expect(message.text).to eq text.join("\r\n")
          expect(message.user_settings).to include({ 'user_id' => user1.id, 'path' => 'INBOX' })
          expect(message.user_settings).to include({ 'user_id' => user2.id, 'path' => 'INBOX' })
          expect(message.user_settings).to include({ 'user_id' => user3.id, 'path' => 'INBOX' })
          expect(message.to_member_name).to eq group1.name
          expect(message.from_member_name).to eq user.long_name
          expect(message.to_member_ids).to be_blank
          expect(message.cc_member_ids).to be_blank
          expect(message.bcc_member_ids).to be_blank
          expect(message.to_webmail_address_group_ids).to be_blank
          expect(message.cc_webmail_address_group_ids).to be_blank
          expect(message.bcc_webmail_address_group_ids).to be_blank
          expect(message.to_shared_address_group_ids).to eq [ group1.id ]
          expect(message.cc_shared_address_group_ids).to eq [ group2.id ]
          expect(message.bcc_shared_address_group_ids).to eq [ group3.id ]
        end
      end
    end

    context '個人全選択パターン' do
      it do
        visit gws_memo_messages_path(site)
        click_on I18n.t('ss.links.new')
        click_on I18n.t("webmail.links.show_cc_bcc")

        within 'form#item-form' do
          within 'dl.see.all' do
            wait_for_cbox_opened { click_on I18n.t('modules.gws/shared_address') }
          end
        end
        within_cbox do
          check "to_all"
          check "cc_all"
          check "bcc_all"
          wait_cbox_close { click_on I18n.t('ss.links.select') }
        end
        within 'form#item-form' do
          within 'dl.see.to' do
            expect(page).to have_css(".index", text: user1.long_name)
            expect(page).to have_css(".index", text: user2.long_name)
            expect(page).to have_css(".index", text: user3.long_name)
          end
          within 'dl.see.cc' do
            expect(page).to have_css(".index", text: user1.long_name)
            expect(page).to have_css(".index", text: user2.long_name)
            expect(page).to have_css(".index", text: user3.long_name)
          end
          within 'dl.see.bcc' do
            expect(page).to have_css(".index", text: user1.long_name)
            expect(page).to have_css(".index", text: user2.long_name)
            expect(page).to have_css(".index", text: user3.long_name)
          end
          fill_in 'item[subject]', with: subject
          fill_in 'item[text]', with: text.join("\n")
          page.accept_confirm do
            click_on I18n.t('ss.buttons.send')
          end
        end
        wait_for_notice I18n.t('ss.notice.sent')

        expect(Gws::Memo::Message.all.count).to eq 1
        Gws::Memo::Message.all.first.tap do |message|
          expect(message.subject).to eq subject
          expect(message.text).to eq text.join("\r\n")
          expect(message.user_settings).to include({ 'user_id' => user1.id, 'path' => 'INBOX' })
          expect(message.user_settings).to include({ 'user_id' => user2.id, 'path' => 'INBOX' })
          expect(message.user_settings).to include({ 'user_id' => user3.id, 'path' => 'INBOX' })
          expect(message.to_member_name).to include(user1.long_name, user2.long_name, user3.long_name)
          expect(message.from_member_name).to eq user.long_name
          expect(message.to_member_ids).to have_at_least(3).items
          expect(message.to_member_ids).to include(user1.id, user2.id, user3.id)
          expect(message.cc_member_ids).to have_at_least(3).items
          expect(message.cc_member_ids).to include(user1.id, user2.id, user3.id)
          expect(message.bcc_member_ids).to have_at_least(3).items
          expect(message.bcc_member_ids).to include(user1.id, user2.id, user3.id)
          expect(message.to_webmail_address_group_ids).to be_blank
          expect(message.cc_webmail_address_group_ids).to be_blank
          expect(message.bcc_webmail_address_group_ids).to be_blank
          expect(message.to_shared_address_group_ids).to be_blank
          expect(message.cc_shared_address_group_ids).to be_blank
          expect(message.bcc_shared_address_group_ids).to be_blank
        end
      end
    end

    context 'グループ全選択パターン' do
      it do
        visit gws_memo_messages_path(site)
        click_on I18n.t('ss.links.new')
        click_on I18n.t("webmail.links.show_cc_bcc")
        within 'form#item-form' do
          within 'dl.see.all' do
            wait_for_cbox_opened { click_on I18n.t('modules.gws/shared_address') }
          end
        end
        within_cbox do
          click_on I18n.t('mongoid.models.gws/shared_address/group')
          check "g_to_all"
          check "g_cc_all"
          check "g_bcc_all"
          wait_cbox_close { click_on I18n.t('ss.links.select') }
        end
        within 'form#item-form' do
          within 'dl.see.to' do
            expect(page).to have_css(".index", text: group1.name)
            expect(page).to have_css(".index", text: group2.name)
            expect(page).to have_css(".index", text: group3.name)
          end
          within 'dl.see.cc' do
            expect(page).to have_css(".index", text: group1.name)
            expect(page).to have_css(".index", text: group2.name)
            expect(page).to have_css(".index", text: group3.name)
          end
          within 'dl.see.bcc' do
            expect(page).to have_css(".index", text: group1.name)
            expect(page).to have_css(".index", text: group2.name)
            expect(page).to have_css(".index", text: group3.name)
          end
          fill_in 'item[subject]', with: subject
          fill_in 'item[text]', with: text.join("\n")
          page.accept_confirm do
            click_on I18n.t('ss.buttons.send')
          end
        end
        wait_for_notice I18n.t('ss.notice.sent')

        expect(Gws::Memo::Message.all.count).to eq 1
        Gws::Memo::Message.all.first.tap do |message|
          expect(message.subject).to eq subject
          expect(message.text).to eq text.join("\r\n")
          expect(message.user_settings).to include({ 'user_id' => user1.id, 'path' => 'INBOX' })
          expect(message.user_settings).to include({ 'user_id' => user2.id, 'path' => 'INBOX' })
          expect(message.user_settings).to include({ 'user_id' => user3.id, 'path' => 'INBOX' })
          expect(message.to_member_name).to include(group1.name, group2.name, group3.name)
          expect(message.from_member_name).to eq user.long_name
          expect(message.to_member_ids).to be_blank
          expect(message.cc_member_ids).to be_blank
          expect(message.bcc_member_ids).to be_blank
          expect(message.to_webmail_address_group_ids).to be_blank
          expect(message.cc_webmail_address_group_ids).to be_blank
          expect(message.bcc_webmail_address_group_ids).to be_blank
          expect(message.to_shared_address_group_ids).to have(3).items
          expect(message.to_shared_address_group_ids).to include(group1.id, group2.id, group3.id)
          expect(message.cc_shared_address_group_ids).to have(3).items
          expect(message.cc_shared_address_group_ids).to include(group1.id, group2.id, group3.id)
          expect(message.bcc_shared_address_group_ids).to have(3).items
          expect(message.bcc_shared_address_group_ids).to include(group1.id, group2.id, group3.id)
        end
      end
    end
  end

  context '個人アドレス帳' do
    let!(:address_group1) { create :webmail_address_group, cur_user: user, order: 10 }
    let!(:address_group2) { create :webmail_address_group, cur_user: user, order: 20 }
    let!(:address_group3) { create :webmail_address_group, cur_user: user, order: 30 }
    let!(:address1) do
      create :webmail_address, cur_user: user, address_group: address_group1, member: user1
    end
    let!(:address2) do
      create :webmail_address, cur_user: user, address_group: address_group2, member: user2
    end
    let!(:address3) do
      create :webmail_address, cur_user: user, address_group: address_group2, member: user3
    end

    context "個人" do
      it do
        visit gws_memo_messages_path(site)
        click_on I18n.t('ss.links.new')
        click_on I18n.t("webmail.links.show_cc_bcc")
        within 'form#item-form' do
          within 'dl.see.all' do
            wait_for_cbox_opened { click_on I18n.t('mongoid.models.webmail/address') }
          end
        end
        within_cbox do
          check "to_ids#{address1.id}"
          check "cc_ids#{address2.id}"
          check "bcc_ids#{address3.id}"
          wait_cbox_close { click_on I18n.t('ss.links.select') }
        end
        within 'form#item-form' do
          within 'dl.see.to' do
            expect(page).to have_css(".index", text: user1.long_name)
          end
          within 'dl.see.cc' do
            expect(page).to have_css(".index", text: user2.long_name)
          end
          within 'dl.see.bcc' do
            expect(page).to have_css(".index", text: user3.long_name)
          end
          fill_in 'item[subject]', with: subject
          fill_in 'item[text]', with: text.join("\n")
          page.accept_confirm do
            click_on I18n.t('ss.buttons.send')
          end
        end
        wait_for_notice I18n.t('ss.notice.sent')

        expect(Gws::Memo::Message.all.count).to eq 1
        Gws::Memo::Message.all.first.tap do |message|
          expect(message.subject).to eq subject
          expect(message.text).to eq text.join("\r\n")
          expect(message.user_settings).to include({ 'user_id' => user1.id, 'path' => 'INBOX' })
          expect(message.user_settings).to include({ 'user_id' => user2.id, 'path' => 'INBOX' })
          expect(message.user_settings).to include({ 'user_id' => user3.id, 'path' => 'INBOX' })
          expect(message.to_member_name).to eq user1.long_name
          expect(message.from_member_name).to eq user.long_name
          expect(message.to_member_ids).to eq [ user1.id ]
          expect(message.cc_member_ids).to eq [ user2.id ]
          expect(message.bcc_member_ids).to eq [ user3.id ]
          expect(message.to_webmail_address_group_ids).to be_blank
          expect(message.cc_webmail_address_group_ids).to be_blank
          expect(message.bcc_webmail_address_group_ids).to be_blank
          expect(message.to_shared_address_group_ids).to be_blank
          expect(message.cc_shared_address_group_ids).to be_blank
          expect(message.bcc_shared_address_group_ids).to be_blank
        end
      end
    end

    context "グループ" do
      it do
        visit gws_memo_messages_path(site)
        click_on I18n.t('ss.links.new')
        click_on I18n.t("webmail.links.show_cc_bcc")
        within 'form#item-form' do
          within 'dl.see.all' do
            wait_for_cbox_opened { click_on I18n.t('mongoid.models.webmail/address') }
          end
        end
        within_cbox do
          click_on I18n.t('mongoid.models.webmail/address_group')
          check "to_ids#{address_group1.id}"
          check "cc_ids#{address_group2.id}"
          check "bcc_ids#{address_group3.id}"
          wait_cbox_close { click_on I18n.t('ss.links.select') }
        end
        within 'form#item-form' do
          within 'dl.see.to' do
            expect(page).to have_css(".index", text: address_group1.name)
          end
          within 'dl.see.cc' do
            expect(page).to have_css(".index", text: address_group2.name)
          end
          within 'dl.see.bcc' do
            expect(page).to have_css(".index", text: address_group3.name)
          end
          fill_in 'item[subject]', with: subject
          fill_in 'item[text]', with: text.join("\n")
          page.accept_confirm do
            click_on I18n.t('ss.buttons.send')
          end
        end
        wait_for_notice I18n.t('ss.notice.sent')

        expect(Gws::Memo::Message.all.count).to eq 1
        Gws::Memo::Message.all.first.tap do |message|
          expect(message.subject).to eq subject
          expect(message.text).to eq text.join("\r\n")
          expect(message.user_settings).to include({ 'user_id' => user1.id, 'path' => 'INBOX' })
          expect(message.user_settings).to include({ 'user_id' => user2.id, 'path' => 'INBOX' })
          expect(message.user_settings).to include({ 'user_id' => user3.id, 'path' => 'INBOX' })
          expect(message.to_member_name).to eq address_group1.name
          expect(message.from_member_name).to eq user.long_name
          expect(message.to_member_ids).to be_blank
          expect(message.cc_member_ids).to be_blank
          expect(message.bcc_member_ids).to be_blank
          expect(message.to_webmail_address_group_ids).to eq [ address_group1.id ]
          expect(message.cc_webmail_address_group_ids).to eq [ address_group2.id ]
          expect(message.bcc_webmail_address_group_ids).to eq [ address_group3.id ]
          expect(message.to_shared_address_group_ids).to be_blank
          expect(message.cc_shared_address_group_ids).to be_blank
          expect(message.bcc_shared_address_group_ids).to be_blank
        end
      end
    end

    context "個人全選択" do
      it do
        visit gws_memo_messages_path(site)
        click_on I18n.t('ss.links.new')
        click_on I18n.t("webmail.links.show_cc_bcc")
        within 'form#item-form' do
          within 'dl.see.all' do
            wait_for_cbox_opened { click_on I18n.t('mongoid.models.webmail/address') }
          end
        end
        within_cbox do
          check "to_all"
          check "cc_all"
          check "bcc_all"
          wait_cbox_close { click_on I18n.t('ss.links.select') }
        end
        within 'form#item-form' do
          within 'dl.see.to' do
            expect(page).to have_css(".index", text: user1.long_name)
            expect(page).to have_css(".index", text: user2.long_name)
            expect(page).to have_css(".index", text: user3.long_name)
          end
          within 'dl.see.cc' do
            expect(page).to have_css(".index", text: user1.long_name)
            expect(page).to have_css(".index", text: user2.long_name)
            expect(page).to have_css(".index", text: user3.long_name)
          end
          within 'dl.see.bcc' do
            expect(page).to have_css(".index", text: user1.long_name)
            expect(page).to have_css(".index", text: user2.long_name)
            expect(page).to have_css(".index", text: user3.long_name)
          end
          fill_in 'item[subject]', with: subject
          fill_in 'item[text]', with: text.join("\n")

          page.accept_confirm do
            click_on I18n.t('ss.buttons.send')
          end
        end
        wait_for_notice I18n.t('ss.notice.sent')

        expect(Gws::Memo::Message.all.count).to eq 1
        Gws::Memo::Message.all.first.tap do |message|
          expect(message.subject).to eq subject
          expect(message.text).to eq text.join("\r\n")
          expect(message.user_settings).to include({ 'user_id' => user1.id, 'path' => 'INBOX' })
          expect(message.user_settings).to include({ 'user_id' => user2.id, 'path' => 'INBOX' })
          expect(message.user_settings).to include({ 'user_id' => user3.id, 'path' => 'INBOX' })
          expect(message.to_member_name).to include(user1.long_name, user2.long_name, user3.long_name)
          expect(message.from_member_name).to eq user.long_name
          expect(message.to_member_ids).to have(3).items
          expect(message.to_member_ids).to include(user1.id, user2.id, user3.id)
          expect(message.cc_member_ids).to have(3).items
          expect(message.cc_member_ids).to include(user1.id, user2.id, user3.id)
          expect(message.bcc_member_ids).to have(3).items
          expect(message.bcc_member_ids).to include(user1.id, user2.id, user3.id)
          expect(message.to_webmail_address_group_ids).to be_blank
          expect(message.cc_webmail_address_group_ids).to be_blank
          expect(message.bcc_webmail_address_group_ids).to be_blank
          expect(message.to_shared_address_group_ids).to be_blank
          expect(message.cc_shared_address_group_ids).to be_blank
          expect(message.bcc_shared_address_group_ids).to be_blank
        end
      end
    end

    context "グループ全選択" do
      it do
        visit gws_memo_messages_path(site)
        click_on I18n.t('ss.links.new')
        click_on I18n.t("webmail.links.show_cc_bcc")
        within 'form#item-form' do
          within 'dl.see.all' do
            wait_for_cbox_opened { click_on I18n.t('mongoid.models.webmail/address') }
          end
        end

        within_cbox do
          click_on I18n.t('mongoid.models.webmail/address_group')
          check "p_to_all"
          check "p_cc_all"
          check "p_bcc_all"
          wait_cbox_close { click_on I18n.t('ss.links.select') }
        end

        within 'form#item-form' do
          within 'dl.see.to' do
            expect(page).to have_css(".index", text: address_group1.name)
            expect(page).to have_css(".index", text: address_group2.name)
            expect(page).to have_css(".index", text: address_group3.name)
          end
          within 'dl.see.cc' do
            expect(page).to have_css(".index", text: address_group1.name)
            expect(page).to have_css(".index", text: address_group2.name)
            expect(page).to have_css(".index", text: address_group3.name)
          end
          within 'dl.see.bcc' do
            expect(page).to have_css(".index", text: address_group1.name)
            expect(page).to have_css(".index", text: address_group2.name)
            expect(page).to have_css(".index", text: address_group3.name)
          end
          fill_in 'item[subject]', with: subject
          fill_in 'item[text]', with: text.join("\n")

          page.accept_confirm do
            click_on I18n.t('ss.buttons.send')
          end
        end
        wait_for_notice I18n.t('ss.notice.sent')

        expect(Gws::Memo::Message.all.count).to eq 1
        Gws::Memo::Message.all.first.tap do |message|
          expect(message.subject).to eq subject
          expect(message.text).to eq text.join("\r\n")
          expect(message.user_settings).to include({ 'user_id' => user1.id, 'path' => 'INBOX' })
          expect(message.user_settings).to include({ 'user_id' => user2.id, 'path' => 'INBOX' })
          expect(message.user_settings).to include({ 'user_id' => user3.id, 'path' => 'INBOX' })
          expect(message.to_member_name).to include(address_group1.name, address_group2.name, address_group3.name)
          expect(message.from_member_name).to eq user.long_name
          expect(message.to_member_ids).to be_blank
          expect(message.cc_member_ids).to be_blank
          expect(message.bcc_member_ids).to be_blank
          expect(message.to_webmail_address_group_ids).to have(3).items
          expect(message.to_webmail_address_group_ids).to include(address_group1.id, address_group2.id, address_group3.id)
          expect(message.cc_webmail_address_group_ids).to have(3).items
          expect(message.cc_webmail_address_group_ids).to include(address_group1.id, address_group2.id, address_group3.id)
          expect(message.bcc_webmail_address_group_ids).to have(3).items
          expect(message.bcc_webmail_address_group_ids).to include(address_group1.id, address_group2.id, address_group3.id)
          expect(message.to_shared_address_group_ids).to be_blank
          expect(message.cc_shared_address_group_ids).to be_blank
          expect(message.bcc_shared_address_group_ids).to be_blank
        end
      end
    end
  end
end
