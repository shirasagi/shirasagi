require 'spec_helper'

describe 'gws_memo_messages', type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:subject) { "subject-#{unique_id}" }
  let(:text) { ("text-#{unique_id}\r\n" * 3).strip }
  before { login_gws_user }

  context '組織アドレス' do
    let!(:user1) { create(:gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids) }
    let!(:user2) { create(:gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids) }

    it '個人' do
      visit gws_memo_messages_path(site)
      click_on I18n.t('ss.links.new')

      within 'form#item-form' do
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
        within 'dl.see.to' do
          expect(page).to have_css(".index", text: user1.name)
        end
        within 'dl.see.cc' do
          expect(page).to have_css(".index", text: user1.name)
        end
        within 'dl.see.bcc' do
          expect(page).to have_css(".index", text: user1.name)
        end
        fill_in 'item[subject]', with: subject
        fill_in 'item[text]', with: text
        accept_confirm do
          click_on I18n.t('gws/memo/message.commit_params_check')
        end
      end
      wait_for_notice I18n.t("ss.notice.sent")
    end

    it '全選択' do
      visit gws_memo_messages_path(site)
      click_on I18n.t('ss.links.new')

      within 'form#item-form' do
        click_on I18n.t("webmail.links.show_cc_bcc")
        within 'dl.see.all' do
          wait_cbox_open { click_on I18n.t('gws.organization_addresses') }
        end
      end
      wait_for_cbox do
        check "to_all"
        check "cc_all"
        check "bcc_all"
        click_on '選択する'
      end
      within 'form#item-form' do
        within 'dl.see.to' do
          expect(page).to have_css(".index", text: user1.name)
          expect(page).to have_css(".index", text: user2.name)
        end
        within 'dl.see.cc' do
          expect(page).to have_css(".index", text: user1.name)
          expect(page).to have_css(".index", text: user2.name)
        end
        within 'dl.see.bcc' do
          expect(page).to have_css(".index", text: user1.name)
          expect(page).to have_css(".index", text: user2.name)
        end
        fill_in 'item[subject]', with: subject
        fill_in 'item[text]', with: text
        page.accept_confirm do
          click_on I18n.t("ss.buttons.send")
        end
      end
      expect(page).to have_css('#notice', text: I18n.t("ss.notice.sent"))
    end
  end

  context '共有アドレス' do
      let!(:group1) { create(:gws_shared_address_group, cur_site: site, cur_user: user) }
      let!(:group2) { create(:gws_shared_address_group, cur_site: site, cur_user: user) }
      let!(:address1) do
        create(:gws_shared_address_address, cur_site: site, cur_user: user, address_group_id: group1.id, member_id: user.id)
      end
      let!(:address2) do
        create(:gws_shared_address_address, cur_site: site, cur_user: user, address_group_id: group2.id, member_id: user.id)
      end

      it "個人" do
        visit gws_memo_messages_path(site)
        click_on I18n.t('ss.links.new')
        click_on I18n.t("webmail.links.show_cc_bcc")
        within 'form#item-form' do
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
          within 'dl.see.to' do
            expect(page).to have_css(".index", text: "#{address1.cur_user.name} (#{address1.cur_user.uid})")
          end
          within 'dl.see.cc' do
            expect(page).to have_css(".index", text: "#{address1.cur_user.name} (#{address1.cur_user.uid})")
          end
          within 'dl.see.bcc' do
            expect(page).to have_css(".index", text: "#{address1.cur_user.name} (#{address1.cur_user.uid})")
          end
          fill_in 'item[subject]', with: subject
          fill_in 'item[text]', with: text
          page.accept_confirm do
            click_on I18n.t('ss.buttons.send')
          end
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.sent'))
      end

      it "グループ" do
        visit gws_memo_messages_path(site)
        click_on I18n.t('ss.links.new')
        click_on I18n.t("webmail.links.show_cc_bcc")
        within 'form#item-form' do
          within 'dl.see.all' do
            wait_cbox_open { click_on I18n.t('modules.gws/shared_address') }
          end
        end
        wait_for_cbox do
          click_on I18n.t('mongoid.models.gws/shared_address/group')
          check "to_ids#{group1.id}"
          check "cc_ids#{group1.id}"
          check "bcc_ids#{group1.id}"
          click_on I18n.t('ss.links.select')
        end
        within 'form#item-form' do
          within 'dl.see.to' do
            expect(page).to have_css(".index", text: group1.name)
          end
          within 'dl.see.cc' do
            expect(page).to have_css(".index", text: group1.name)
          end
          within 'dl.see.bcc' do
            expect(page).to have_css(".index", text: group1.name)
          end
          fill_in 'item[subject]', with: subject
          fill_in 'item[text]', with: text
          page.accept_confirm do
            click_on I18n.t('ss.buttons.send')
          end
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.sent'))
      end

      it '個人全選択パターン' do
        visit gws_memo_messages_path(site)
        click_on I18n.t('ss.links.new')
        click_on I18n.t("webmail.links.show_cc_bcc")
        within 'form#item-form' do
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
          within 'dl.see.to' do
            expect(page).to have_css(".index", text: "#{address1.cur_user.name} (#{address1.cur_user.uid})")
            expect(page).to have_css(".index", text: "#{address2.cur_user.name} (#{address2.cur_user.uid})")
          end
          within 'dl.see.cc' do
            expect(page).to have_css(".index", text: "#{address1.cur_user.name} (#{address1.cur_user.uid})")
            expect(page).to have_css(".index", text: "#{address2.cur_user.name} (#{address2.cur_user.uid})")
          end
          within 'dl.see.bcc' do
            expect(page).to have_css(".index", text: "#{address1.cur_user.name} (#{address1.cur_user.uid})")
            expect(page).to have_css(".index", text: "#{address2.cur_user.name} (#{address2.cur_user.uid})")
          end
          fill_in 'item[subject]', with: subject
          fill_in 'item[text]', with: text
          page.accept_confirm do
            click_on I18n.t('ss.buttons.send')
          end
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.sent'))
      end

      it 'グループ全選択パターン' do
        visit gws_memo_messages_path(site)
        click_on I18n.t('ss.links.new')
        click_on I18n.t("webmail.links.show_cc_bcc")
        within 'form#item-form' do
          within 'dl.see.all' do
            wait_cbox_open { click_on I18n.t('modules.gws/shared_address') }
          end
        end
        wait_for_cbox do
          click_on I18n.t('mongoid.models.gws/shared_address/group')
          check "g_to_all"
          check "g_cc_all"
          check "g_bcc_all"
          click_on I18n.t('ss.links.select')
        end
        within 'form#item-form' do
          within 'dl.see.to' do
            expect(page).to have_css(".index", text: group1.name)
            expect(page).to have_css(".index", text: group2.name)
          end
          within 'dl.see.cc' do
            expect(page).to have_css(".index", text: group1.name)
            expect(page).to have_css(".index", text: group2.name)
          end
          within 'dl.see.bcc' do
            expect(page).to have_css(".index", text: group1.name)
            expect(page).to have_css(".index", text: group2.name)
          end
          fill_in 'item[subject]', with: subject
          fill_in 'item[text]', with: text
          page.accept_confirm do
            click_on I18n.t('ss.buttons.send')
          end
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.sent'))
      end
  end


  context '個人アドレス帳 ' do
      let!(:address_group1) { create :webmail_address_group, cur_user: gws_user, order: 10 }
      let!(:address_group2) { create :webmail_address_group, cur_user: gws_user, order: 20 }
      let!(:address1) do
        create :webmail_address, cur_user: gws_user, address_group: address_group1, member: gws_user
      end
      let!(:address2) do
        create :webmail_address, cur_user: gws_user, address_group: address_group2, member: gws_user
      end

      it "個人" do
        visit gws_memo_messages_path(site)
        click_on I18n.t('ss.links.new')
        click_on I18n.t("webmail.links.show_cc_bcc")
        within 'form#item-form' do
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
          within 'dl.see.to' do
            expect(page).to have_css(".index", text: "#{user.name} (#{user.uid})")
          end
          within 'dl.see.cc' do
            expect(page).to have_css(".index", text: "#{user.name} (#{user.uid})")
          end
          within 'dl.see.bcc' do
            expect(page).to have_css(".index", text: "#{user.name} (#{user.uid})")
          end
          fill_in 'item[subject]', with: subject
          fill_in 'item[text]', with: text
          page.accept_confirm do
            click_on I18n.t('ss.buttons.send')
          end
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.sent'))
      end

      it "グループ" do
        visit gws_memo_messages_path(site)
        click_on I18n.t('ss.links.new')
        click_on I18n.t("webmail.links.show_cc_bcc")
        within 'form#item-form' do
          within 'dl.see.all' do
            wait_cbox_open { click_on I18n.t('mongoid.models.webmail/address') }
          end
        end
        wait_for_cbox do
          click_on I18n.t('mongoid.models.webmail/address_group')
          check "to_ids#{address_group1.id}"
          check "cc_ids#{address_group1.id}"
          check "bcc_ids#{address_group1.id}"
          click_on I18n.t('ss.links.select')
        end
        within 'form#item-form' do
        within 'dl.see.to' do
          expect(page).to have_css(".index", text: address_group1.name)
        end
        within 'dl.see.cc' do
          expect(page).to have_css(".index", text: address_group1.name)
        end
        within 'dl.see.bcc' do
          expect(page).to have_css(".index", text: address_group1.name)
        end
          fill_in 'item[subject]', with: subject
          fill_in 'item[text]', with: text
          page.accept_confirm do
            click_on I18n.t('ss.buttons.send')
          end
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.sent'))
      end

      it "個人全選択" do
        visit gws_memo_messages_path(site)
        click_on I18n.t('ss.links.new')
        click_on I18n.t("webmail.links.show_cc_bcc")
        within 'form#item-form' do
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
        within 'dl.see.to' do
          expect(page).to have_css(".index", text: "#{address1.cur_user.name} (#{address1.cur_user.uid})")
          expect(page).to have_css(".index", text: "#{address2.cur_user.name} (#{address2.cur_user.uid})")
        end
        within 'dl.see.cc' do
          expect(page).to have_css(".index", text: "#{address1.cur_user.name} (#{address1.cur_user.uid})")
          expect(page).to have_css(".index", text: "#{address2.cur_user.name} (#{address2.cur_user.uid})")
        end
        within 'dl.see.bcc' do
          expect(page).to have_css(".index", text: "#{address1.cur_user.name} (#{address1.cur_user.uid})")
          expect(page).to have_css(".index", text: "#{address2.cur_user.name} (#{address2.cur_user.uid})")
        end
          fill_in 'item[subject]', with: subject
          fill_in 'item[text]', with: text

          page.accept_confirm do
            click_on I18n.t('ss.buttons.send')
          end
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.sent'))
      end

      it "グループ全選択" do
        visit gws_memo_messages_path(site)
        click_on I18n.t('ss.links.new')
        click_on I18n.t("webmail.links.show_cc_bcc")
        within 'form#item-form' do
          within 'dl.see.all' do
            wait_cbox_open { click_on I18n.t('mongoid.models.webmail/address') }
          end
        end

        wait_for_cbox do
          click_on I18n.t('mongoid.models.webmail/address_group')
          check "p_to_all"
          check "p_cc_all"
          check "p_bcc_all"
          click_on I18n.t('ss.links.select')
          sleep(1)
        end

        within 'form#item-form' do
          within 'dl.see.to' do
            expect(page).to have_css(".index", text: address_group1.name)
            expect(page).to have_css(".index", text: address_group2.name)
          end
          within 'dl.see.cc' do
            expect(page).to have_css(".index", text: address_group1.name)
            expect(page).to have_css(".index", text: address_group2.name)
          end
          within 'dl.see.bcc' do
            expect(page).to have_css(".index", text: address_group1.name)
            expect(page).to have_css(".index", text: address_group2.name)
          end
          fill_in 'item[subject]', with: subject
          fill_in 'item[text]', with: text

          page.accept_confirm do
            click_on I18n.t('ss.buttons.send')
          end
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.sent'))
      end
  end
end
