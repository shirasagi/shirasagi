require 'spec_helper'

describe "webmail_mails", type: :feature, dbscope: :example, js: true, imap: true do
  let(:now) { Time.zone.now.change(usec: 0) }

  context "webmail_mode is account" do
    let(:user) { webmail_imap }
    let!(:mail1) { Mail.new(date: now - 25.minutes, from: "from-1@example.jp", to: user.email, subject: "subject-1") }
    let!(:mail2) { Mail.new(date: now - 20.minutes, from: "from-2@example.jp", to: user.email, subject: "subject-2") }
    let!(:mail3) { Mail.new(date: now - 15.minutes, from: "from-3@example.jp", to: user.email, subject: "subject-3") }

    before do
      Timecop.freeze(now - 25.minutes) { webmail_import_mail(user, mail1) }
      # mail2 は無害化処理に時間がかかったため、mail3 より遅れて届いた: date と date.recieved (IMAP INTERNALDATE) とが乖離
      Timecop.freeze(now - 12.minutes) { webmail_import_mail(user, mail2) }
      Timecop.freeze(now - 15.minutes) { webmail_import_mail(user, mail3) }

      login_user(user)
    end

    context "prev / next navigation" do
      it do
        visit webmail_mails_path(account: 0)

        within ".list-items" do
          expect(page).to have_css(".list-item", count: 3)
          find_all(".list-item").tap do |list_items|
            expect(list_items[0]).to have_css(".info", text: mail2.subject)
            expect(list_items[1]).to have_css(".info", text: mail3.subject)
            expect(list_items[2]).to have_css(".info", text: mail1.subject)
          end

          click_on mail3.subject
          wait_for_js_ready

          within ".move-tool-wrap" do
            expect(page).to have_css(".page-order .current", text: "2")
            expect(page).to have_css(".page-order .total", text: "3")
            click_on "arrow_circle_right"
          end
          wait_for_js_ready

          expect(page).to have_css(".subject", text: mail1.subject)
          within ".move-tool-wrap" do
            expect(page).to have_css(".page-order", text: "3 / 3")
            expect(page).to have_css(".next.inactive", text: "arrow_circle_right")
            click_on "arrow_circle_left"
          end
          wait_for_js_ready

          expect(page).to have_css(".subject", text: mail3.subject)
          within ".move-tool-wrap" do
            expect(page).to have_css(".page-order", text: "2 / 3")
            click_on "arrow_circle_left"
          end
          wait_for_js_ready

          expect(page).to have_css(".subject", text: mail2.subject)
          within ".move-tool-wrap" do
            expect(page).to have_css(".page-order", text: "1 / 3")
            expect(page).to have_css(".prev.inactive", text: "arrow_circle_left")
          end
        end
      end
    end
  end

  context "webmail_mode is group" do
    let!(:group) { create :webmail_group }
    let!(:user) { webmail_imap }
    let!(:mail1) { Mail.new(date: now - 25.minutes, from: "from-1@example.jp", to: group.contact_email, subject: "subject-1") }
    let!(:mail2) { Mail.new(date: now - 20.minutes, from: "from-2@example.jp", to: group.contact_email, subject: "subject-2") }
    let!(:mail3) { Mail.new(date: now - 15.minutes, from: "from-3@example.jp", to: group.contact_email, subject: "subject-3") }

    before do
      Timecop.freeze(now - 25.minutes) { webmail_import_mail(group, mail1) }
      # mail2 は無害化処理に時間がかかったため、mail3 より遅れて届いた: date と date.recieved (IMAP INTERNALDATE) とが乖離
      Timecop.freeze(now - 12.minutes) { webmail_import_mail(group, mail2) }
      Timecop.freeze(now - 15.minutes) { webmail_import_mail(group, mail3) }

      user.add_to_set(group_ids: [ group.id ])

      login_user(user)
    end

    context "message sort" do
      it do
        visit webmail_mails_path(webmail_mode: "group", account: group.id)

        within ".list-items" do
          expect(page).to have_css(".list-item", count: 3)
          find_all(".list-item").tap do |list_items|
            expect(list_items[0]).to have_css(".info", text: mail2.subject)
            expect(list_items[1]).to have_css(".info", text: mail3.subject)
            expect(list_items[2]).to have_css(".info", text: mail1.subject)
          end

          click_on mail3.subject
          within ".move-tool-wrap" do
            expect(page).to have_css(".page-order", text: "2 / 3")
            click_on "arrow_circle_right"
          end

          expect(page).to have_css(".subject", text: mail1.subject)
          within ".move-tool-wrap" do
            expect(page).to have_css(".page-order", text: "3 / 3")
            expect(page).to have_css(".next.inactive", text: "arrow_circle_right")
            click_on "arrow_circle_left"
          end

          expect(page).to have_css(".subject", text: mail3.subject)
          within ".move-tool-wrap" do
            expect(page).to have_css(".page-order", text: "2 / 3")
            click_on "arrow_circle_left"
          end

          expect(page).to have_css(".subject", text: mail2.subject)
          within ".move-tool-wrap" do
            expect(page).to have_css(".page-order", text: "1 / 3")
            expect(page).to have_css(".prev.inactive", text: "arrow_circle_left")
          end
        end
      end
    end
  end
end
