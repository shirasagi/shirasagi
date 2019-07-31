require 'spec_helper'

describe 'gws_memo_messages', type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:recipient) { create(:gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids) }
  let(:subject) { "subject-#{unique_id}" }
  let(:body) { "body-#{unique_id}" }

  context 'when subject_match? be true' do
    let!(:filter) { create :gws_memo_filter, subject: subject }

    before do
      login_gws_user
    end

    it do
      visit gws_memo_messages_path(site)
      click_on I18n.t('ss.links.new')

      within 'form#item-form' do
        click_on I18n.t("webmail.links.show_cc_bcc")

        within 'dl.see.to' do
          click_on I18n.t('gws.organization_addresses')
        end
      end

      wait_for_cbox do
        expect(page).to have_content(gws_user.name)
        click_on gws_user.name
      end

      within 'form#item-form' do
        fill_in 'item[subject]', with: subject
        fill_in 'item[text]', with: body

        page.accept_confirm do
          click_on I18n.t("ss.buttons.send")
        end
      end
      expect(page).to have_css('#notice', text: I18n.t("ss.notice.sent"))
      expect(page).to have_no_content(subject)

      visit gws_memo_messages_path(site, folder: 'INBOX.Trash')
      expect(page).to have_content(subject)
    end
  end

  context 'when body_match? be true' do
    let!(:filter) { create :gws_memo_filter, body: body }

    before do
      login_gws_user
    end

    it do
      visit gws_memo_messages_path(site)
      click_on I18n.t('ss.links.new')

      within 'form#item-form' do
        click_on I18n.t("webmail.links.show_cc_bcc")

        within 'dl.see.to' do
          click_on I18n.t('gws.organization_addresses')
        end
      end

      wait_for_cbox do
        expect(page).to have_content(gws_user.name)
        click_on gws_user.name
      end

      within 'form#item-form' do
        fill_in 'item[subject]', with: subject
        select 'HTML'
        fill_in_ckeditor "item[html]", with: body

        page.accept_confirm do
          click_on I18n.t("ss.buttons.send")
        end
      end
      expect(page).to have_css('#notice', text: I18n.t("ss.notice.sent"))
      expect(page).to have_no_content(subject)

      visit gws_memo_messages_path(site, folder: 'INBOX.Trash')
      expect(page).to have_content(subject)
    end
  end

  context 'when from_match? be true' do
    let!(:filter) { create :gws_memo_filter, body: subject, from_member_ids: [gws_user.id] }

    before do
      login_gws_user
    end

    it do
      visit gws_memo_messages_path(site)
      click_on I18n.t('ss.links.new')

      within 'form#item-form' do
        click_on I18n.t("webmail.links.show_cc_bcc")

        within 'dl.see.to' do
          click_on I18n.t('gws.organization_addresses')
        end
      end

      wait_for_cbox do
        expect(page).to have_content(gws_user.name)
        click_on gws_user.name
      end

      within 'form#item-form' do
        fill_in 'item[subject]', with: subject
        fill_in 'item[text]', with: body

        page.accept_confirm do
          click_on I18n.t("ss.buttons.send")
        end
      end
      expect(page).to have_css('#notice', text: I18n.t("ss.notice.sent"))
      expect(page).to have_no_content(subject)

      visit gws_memo_messages_path(site, folder: 'INBOX.Trash')
      expect(page).to have_content(subject)
    end
  end

  context 'when from_match? be true' do
    let!(:filter) { create :gws_memo_filter, body: subject, from_member_ids: [gws_user.id] }

    before do
      login_gws_user
    end

    it do
      visit gws_memo_messages_path(site)
      click_on I18n.t('ss.links.new')

      within 'form#item-form' do
        click_on I18n.t("webmail.links.show_cc_bcc")

        within 'dl.see.to' do
          click_on I18n.t('gws.organization_addresses')
        end
      end

      wait_for_cbox do
        expect(page).to have_content(gws_user.name)
        click_on gws_user.name
      end

      within 'form#item-form' do
        fill_in 'item[subject]', with: subject
        fill_in 'item[text]', with: body

        page.accept_confirm do
          click_on I18n.t("ss.buttons.send")
        end
      end
      expect(page).to have_css('#notice', text: I18n.t("ss.notice.sent"))
      expect(page).to have_no_content(subject)

      visit gws_memo_messages_path(site, folder: 'INBOX.Trash')
      expect(page).to have_content(subject)
    end
  end

  context 'when to_match? be true' do
    let!(:filter) { create :gws_memo_filter, from_member_ids: [recipient.id], to_member_ids: [gws_user.id] }

    before do
      login_gws_user
    end

    it do
      visit gws_memo_messages_path(site)
      click_on I18n.t('ss.links.new')

      within 'form#item-form' do
        click_on I18n.t("webmail.links.show_cc_bcc")

        within 'dl.see.to' do
          click_on I18n.t('gws.organization_addresses')
        end
      end

      wait_for_cbox do
        expect(page).to have_content(gws_user.name)
        click_on gws_user.name
      end

      within 'form#item-form' do
        fill_in 'item[subject]', with: subject
        fill_in 'item[text]', with: body

        page.accept_confirm do
          click_on I18n.t("ss.buttons.send")
        end
      end
      expect(page).to have_css('#notice', text: I18n.t("ss.notice.sent"))
      expect(page).to have_no_content(subject)

      visit gws_memo_messages_path(site, folder: 'INBOX.Trash')
      expect(page).to have_content(subject)
    end
  end

  context 'when to_match? be true' do
    let!(:filter) { create :gws_memo_filter, from_member_ids: [recipient.id], to_member_ids: [gws_user.id] }

    before do
      login_gws_user
    end

    it do
      visit gws_memo_messages_path(site)
      click_on I18n.t('ss.links.new')

      within 'form#item-form' do
        click_on I18n.t("webmail.links.show_cc_bcc")

        within 'dl.see.to' do
          click_on I18n.t('gws.organization_addresses')
        end
      end

      wait_for_cbox do
        expect(page).to have_content(gws_user.name)
        click_on gws_user.name
      end

      within 'form#item-form' do
        fill_in 'item[subject]', with: subject
        fill_in 'item[text]', with: body

        page.accept_confirm do
          click_on I18n.t("ss.buttons.send")
        end
      end
      expect(page).to have_css('#notice', text: I18n.t("ss.notice.sent"))
      expect(page).to have_no_content(subject)

      visit gws_memo_messages_path(site, folder: 'INBOX.Trash')
      expect(page).to have_content(subject)
    end
  end

  context 'when match? be false' do
    let!(:filter) { create :gws_memo_filter, from_member_ids: [recipient.id] }

    before do
      login_gws_user
    end

    it do
      visit gws_memo_messages_path(site)
      click_on I18n.t('ss.links.new')

      within 'form#item-form' do
        click_on I18n.t("webmail.links.show_cc_bcc")

        within 'dl.see.to' do
          click_on I18n.t('gws.organization_addresses')
        end
      end

      wait_for_cbox do
        expect(page).to have_content(gws_user.name)
        click_on gws_user.name
      end

      within 'form#item-form' do
        fill_in 'item[subject]', with: subject
        fill_in 'item[text]', with: body

        page.accept_confirm do
          click_on I18n.t("ss.buttons.send")
        end
      end
      expect(page).to have_css('#notice', text: I18n.t("ss.notice.sent"))
      expect(page).to have_content(subject)

      visit gws_memo_messages_path(site, folder: 'INBOX.Trash')
      expect(page).to have_no_content(subject)
    end
  end
end
