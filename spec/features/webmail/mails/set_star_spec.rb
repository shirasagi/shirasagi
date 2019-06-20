require 'spec_helper'

describe "webmail_mails", type: :feature, dbscope: :example, imap: true, js: true do
  let(:mail1) do
    Mail.new(
      from: "from-#{unique_id}@example.jp",
      to: "to-#{unique_id}@example.jp",
      subject: "subject-#{unique_id}",
      body: "message-#{unique_id}\nmessage-#{unique_id}"
    )
  end

  before do
    webmail_import_mail(webmail_imap, mail1)
    login_webmail_imap
  end

  context 'toggle star on index' do
    it do
      visit webmail_mails_path(account: 0)
      first(".list-item .icon-star.off a").click
      within find("#notice", visible: false) do
        expect(page).to have_content(I18n.t('ss.notice.set_star'))
      end

      visit webmail_mails_path(account: 0)
      first(".list-item .icon-star.on a").click
      within find("#notice", visible: false) do
        expect(page).to have_content(I18n.t('ss.notice.unset_star'))
      end

      visit webmail_mails_path(account: 0)
      first(".list-item .icon-star.off a").click
      within find("#notice", visible: false) do
        expect(page).to have_content(I18n.t('ss.notice.set_star'))
      end
    end
  end

  context 'toggle star to selected mails on index' do
    it do
      visit webmail_mails_path(account: 0)
      first(".list-item input[type=checkbox]").click
      within ".list-head-action" do
        click_on I18n.t("webmail.links.etc")
        click_on I18n.t("webmail.links.set_star")
      end
      within find("#notice", visible: false) do
        expect(page).to have_content(I18n.t('ss.notice.set_star'))
      end
      expect(page).to have_css(".list-item .icon-star.on")

      visit webmail_mails_path(account: 0)
      first(".list-item input[type=checkbox]").click
      within ".list-head-action" do
        click_on I18n.t("webmail.links.etc")
        click_on I18n.t("webmail.links.unset_star")
      end
      within find("#notice", visible: false) do
        expect(page).to have_content(I18n.t('ss.notice.unset_star'))
      end
      expect(page).to have_css(".list-item .icon-star.off")

      visit webmail_mails_path(account: 0)
      first(".list-item input[type=checkbox]").click
      within ".list-head-action" do
        click_on I18n.t("webmail.links.etc")
        click_on I18n.t("webmail.links.set_star")
      end
      within find("#notice", visible: false) do
        expect(page).to have_content(I18n.t('ss.notice.set_star'))
      end
      expect(page).to have_css(".list-item .icon-star.on")
    end
  end

  context 'toggle star on show' do
    it do
      visit webmail_mails_path(account: 0)
      click_on mail1.subject
      first(".webmail-mail .icon-star.off a").click
      within find("#notice", visible: false) do
        expect(page).to have_content(I18n.t('ss.notice.set_star'))
      end

      visit webmail_mails_path(account: 0)
      click_on mail1.subject
      first(".webmail-mail .icon-star.on a").click
      within find("#notice", visible: false) do
        expect(page).to have_content(I18n.t('ss.notice.unset_star'))
      end

      visit webmail_mails_path(account: 0)
      click_on mail1.subject
      first(".webmail-mail .icon-star.off a").click
      within find("#notice", visible: false) do
        expect(page).to have_content(I18n.t('ss.notice.set_star'))
      end
    end
  end
end
