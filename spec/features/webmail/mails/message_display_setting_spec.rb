require 'spec_helper'

describe "webmail_mails message display setting", type: :feature, dbscope: :example, js: true, imap: true do
  let(:now) { Time.zone.now.change(usec: 0) }
  let(:user) { webmail_imap }
  let!(:mail1) { Mail.new(date: now - 20.minutes, from: "from-1@example.jp", to: user.email, subject: "subject-1") }

  before do
    Timecop.freeze(now - 20.minutes) { webmail_import_mail(user, mail1) }
    Webmail.imap_pool.disconnect_all

    login_user(user)
  end

  # ヘッダ列の画面上の左端座標。flex + order による実際の列順（件名と差出人の左右）を検証する。
  def head_field_left(field)
    page.evaluate_script(
      "document.querySelector('ul.webmail-mails .list-item-head .head .#{field}').getBoundingClientRect().left"
    )
  end

  context "default (name_first)" do
    it "does not add subject-first class and shows sender before subject" do
      visit webmail_mails_path(account: 0)

      expect(page).to have_css("ul.webmail-mails")
      expect(page).to have_no_css("ul.webmail-mails.subject-first")
      expect(head_field_left("from")).to be < head_field_left("title")
    end
  end

  context "subject_first" do
    before { user.set(message_list_column_order: "subject_first") }

    it "adds subject-first class and shows subject before sender" do
      visit webmail_mails_path(account: 0)

      expect(page).to have_css("ul.webmail-mails.subject-first .list-item-head .head .title")
      expect(head_field_left("title")).to be < head_field_left("from")
    end
  end
end
