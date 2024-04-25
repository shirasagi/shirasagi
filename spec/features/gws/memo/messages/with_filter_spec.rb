require 'spec_helper'

describe 'gws_memo_messages', type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:recipient) { create(:gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids) }
  let(:subject) { "subject-#{unique_id}" }
  let(:body) { "body-#{unique_id}" }

  context 'when subject_match? be true' do
    let!(:folder) { create :gws_memo_folder, cur_user: gws_user }
    let!(:filter) do
      create(:gws_memo_filter, cur_user: gws_user, subject: subject, action: %w(trash move).sample, folder: folder)
    end

    before do
      login_gws_user
    end

    it do
      visit gws_memo_messages_path(site)
      click_on I18n.t('ss.links.new')

      within 'form#item-form' do
        click_on I18n.t("webmail.links.show_cc_bcc")

        within 'dl.see.all' do
          wait_cbox_open { click_on I18n.t('gws.organization_addresses') }
        end
      end

      within_cbox do
        expect(page).to have_content(gws_user.name)
        wait_cbox_close { click_on gws_user.name }
      end

      within 'form#item-form' do
        within 'dl.see.to' do
          expect(page).to have_css(".index", text: gws_user.name)
        end
        fill_in 'item[subject]', with: subject
        fill_in 'item[text]', with: body

        page.accept_confirm do
          click_on I18n.t("ss.buttons.send")
        end
      end
      wait_for_notice I18n.t("ss.notice.sent")
      expect(page).to have_no_content(subject)

      if filter.action == "trash"
        visit gws_memo_messages_path(site, folder: 'INBOX.Trash')
      else
        visit gws_memo_messages_path(site, folder: folder.id)
      end
      expect(page).to have_content(subject)
    end
  end

  context 'when body_match? be true' do
    let!(:folder) { create :gws_memo_folder, cur_user: gws_user }
    let!(:filter) do
      create :gws_memo_filter, cur_user: gws_user, body: body, action: %w(trash move).sample, folder: folder
    end

    before do
      login_gws_user
    end

    it do
      visit gws_memo_messages_path(site)
      click_on I18n.t('ss.links.new')

      within 'form#item-form' do
        click_on I18n.t("webmail.links.show_cc_bcc")

        within 'dl.see.all' do
          wait_cbox_open { click_on I18n.t('gws.organization_addresses') }
        end
      end

      within_cbox do
        expect(page).to have_content(gws_user.name)
        wait_cbox_close { click_on gws_user.name }
      end

      within 'form#item-form' do
        within 'dl.see.to' do
          expect(page).to have_css(".index", text: gws_user.name)
        end
        fill_in 'item[subject]', with: subject
        select 'HTML'
        fill_in_ckeditor "item[html]", with: body

        page.accept_confirm do
          click_on I18n.t("ss.buttons.send")
        end
      end
      wait_for_notice I18n.t("ss.notice.sent")
      expect(page).to have_no_content(subject)

      if filter.action == "trash"
        visit gws_memo_messages_path(site, folder: 'INBOX.Trash')
      else
        visit gws_memo_messages_path(site, folder: folder.id)
      end
      expect(page).to have_content(subject)
    end
  end

  context 'when from_match? be true' do
    let!(:folder) { create :gws_memo_folder, cur_user: gws_user }
    let!(:filter) do
      create :gws_memo_filter, cur_user: gws_user, body: subject, from_member_ids: [gws_user.id],
             action: %w(trash move).sample, folder: folder
    end

    before do
      login_gws_user
    end

    it do
      visit gws_memo_messages_path(site)
      click_on I18n.t('ss.links.new')

      within 'form#item-form' do
        click_on I18n.t("webmail.links.show_cc_bcc")

        within 'dl.see.all' do
          wait_cbox_open { click_on I18n.t('gws.organization_addresses') }
        end
      end

      within_cbox do
        expect(page).to have_content(gws_user.name)
        wait_cbox_close { click_on gws_user.name }
      end

      within 'form#item-form' do
        within 'dl.see.to' do
          expect(page).to have_css(".index", text: gws_user.name)
        end
        fill_in 'item[subject]', with: subject
        fill_in 'item[text]', with: body

        page.accept_confirm do
          click_on I18n.t("ss.buttons.send")
        end
      end
      wait_for_notice I18n.t("ss.notice.sent")
      expect(page).to have_no_content(subject)

      if filter.action == "trash"
        visit gws_memo_messages_path(site, folder: 'INBOX.Trash')
      else
        visit gws_memo_messages_path(site, folder: folder.id)
      end
      expect(page).to have_content(subject)
    end
  end

  context 'when from_match? be true' do
    let!(:folder) { create :gws_memo_folder, cur_user: gws_user }
    let!(:filter) do
      create :gws_memo_filter, cur_user: gws_user, body: subject, from_member_ids: [gws_user.id],
             action: %w(trash move).sample, folder: folder
    end

    before do
      login_gws_user
    end

    it do
      visit gws_memo_messages_path(site)
      click_on I18n.t('ss.links.new')

      within 'form#item-form' do
        click_on I18n.t("webmail.links.show_cc_bcc")

        within 'dl.see.all' do
          wait_cbox_open { click_on I18n.t('gws.organization_addresses') }
        end
      end

      within_cbox do
        expect(page).to have_content(gws_user.name)
        wait_cbox_close { click_on gws_user.name }
      end

      within 'form#item-form' do
        within 'dl.see.to' do
          expect(page).to have_css(".index", text: gws_user.name)
        end
        fill_in 'item[subject]', with: subject
        fill_in 'item[text]', with: body

        page.accept_confirm do
          click_on I18n.t("ss.buttons.send")
        end
      end
      wait_for_notice I18n.t("ss.notice.sent")
      expect(page).to have_no_content(subject)

      if filter.action == "trash"
        visit gws_memo_messages_path(site, folder: 'INBOX.Trash')
      else
        visit gws_memo_messages_path(site, folder: folder.id)
      end
      expect(page).to have_content(subject)
    end
  end

  context 'when to_match? be true' do
    let!(:folder) { create :gws_memo_folder, cur_user: gws_user }
    let!(:filter) do
      create :gws_memo_filter, cur_user: gws_user, from_member_ids: [recipient.id], to_member_ids: [gws_user.id],
             action: %w(trash move).sample, folder: folder
    end

    before do
      login_gws_user
    end

    it do
      visit gws_memo_messages_path(site)
      click_on I18n.t('ss.links.new')

      within 'form#item-form' do
        click_on I18n.t("webmail.links.show_cc_bcc")

        within 'dl.see.all' do
          wait_cbox_open { click_on I18n.t('gws.organization_addresses') }
        end
      end

      within_cbox do
        expect(page).to have_content(gws_user.name)
        wait_cbox_close { click_on gws_user.name }
      end

      within 'form#item-form' do
        within 'dl.see.to' do
          expect(page).to have_css(".index", text: gws_user.name)
        end
        fill_in 'item[subject]', with: subject
        fill_in 'item[text]', with: body

        page.accept_confirm do
          click_on I18n.t("ss.buttons.send")
        end
      end
      wait_for_notice I18n.t("ss.notice.sent")
      expect(page).to have_no_content(subject)

      if filter.action == "trash"
        visit gws_memo_messages_path(site, folder: 'INBOX.Trash')
      else
        visit gws_memo_messages_path(site, folder: folder.id)
      end
      expect(page).to have_content(subject)
    end
  end

  context 'when to_match? be true' do
    let!(:folder) { create :gws_memo_folder, cur_user: gws_user }
    let!(:filter) do
      create :gws_memo_filter, cur_user: gws_user, from_member_ids: [recipient.id], to_member_ids: [gws_user.id],
             action: %w(trash move).sample, folder: folder
    end

    before do
      login_gws_user
    end

    it do
      visit gws_memo_messages_path(site)
      click_on I18n.t('ss.links.new')

      within 'form#item-form' do
        click_on I18n.t("webmail.links.show_cc_bcc")

        within 'dl.see.all' do
          wait_cbox_open { click_on I18n.t('gws.organization_addresses') }
        end
      end

      within_cbox do
        expect(page).to have_content(gws_user.name)
        wait_cbox_close { click_on gws_user.name }
      end

      within 'form#item-form' do
        within 'dl.see.to' do
          expect(page).to have_css(".index", text: gws_user.name)
        end
        fill_in 'item[subject]', with: subject
        fill_in 'item[text]', with: body

        page.accept_confirm do
          click_on I18n.t("ss.buttons.send")
        end
      end
      wait_for_notice I18n.t("ss.notice.sent")
      expect(page).to have_no_content(subject)

      if filter.action == "trash"
        visit gws_memo_messages_path(site, folder: 'INBOX.Trash')
      else
        visit gws_memo_messages_path(site, folder: folder.id)
      end
      expect(page).to have_content(subject)
    end
  end

  context 'when match? be false' do
    let!(:folder) { create :gws_memo_folder, cur_user: gws_user }
    let!(:filter) do
      create :gws_memo_filter, cur_user: gws_user, from_member_ids: [recipient.id],
             action: %w(trash move).sample, folder: folder
    end

    before do
      login_gws_user
    end

    it do
      visit gws_memo_messages_path(site)
      click_on I18n.t('ss.links.new')

      within 'form#item-form' do
        click_on I18n.t("webmail.links.show_cc_bcc")

        within 'dl.see.all' do
          wait_cbox_open { click_on I18n.t('gws.organization_addresses') }
        end
      end

      within_cbox do
        expect(page).to have_content(gws_user.name)
        wait_cbox_close { click_on gws_user.name }
      end

      within 'form#item-form' do
        within 'dl.see.to' do
          expect(page).to have_css(".index", text: gws_user.name)
        end
        fill_in 'item[subject]', with: subject
        fill_in 'item[text]', with: body

        page.accept_confirm do
          click_on I18n.t("ss.buttons.send")
        end
      end
      wait_for_notice I18n.t("ss.notice.sent")
      expect(page).to have_content(subject)

      if filter.action == "trash"
        visit gws_memo_messages_path(site, folder: 'INBOX.Trash')
      else
        visit gws_memo_messages_path(site, folder: folder.id)
      end
      expect(page).to have_no_content(subject)
    end
  end

  context 'when a folder is not existed' do
    let!(:folder) { create :gws_memo_folder, cur_user: gws_user }
    let!(:filter) do
      create(:gws_memo_filter, cur_user: gws_user, subject: subject, action: "move", folder: folder)
    end

    before do
      folder.destroy
      login_gws_user
    end

    it do
      visit gws_memo_messages_path(site)
      click_on I18n.t('ss.links.new')

      within 'form#item-form' do
        click_on I18n.t("webmail.links.show_cc_bcc")

        within 'dl.see.all' do
          wait_cbox_open { click_on I18n.t('gws.organization_addresses') }
        end
      end

      within_cbox do
        expect(page).to have_content(gws_user.name)
        wait_cbox_close { click_on gws_user.name }
      end

      within 'form#item-form' do
        within 'dl.see.to' do
          expect(page).to have_css(".index", text: gws_user.name)
        end
        fill_in 'item[subject]', with: subject
        fill_in 'item[text]', with: body

        page.accept_confirm do
          click_on I18n.t("ss.buttons.send")
        end
      end
      wait_for_notice I18n.t("ss.notice.sent")

      visit gws_memo_messages_path(site)
      expect(page).to have_content(subject)
    end
  end
end
