require 'spec_helper'

describe 'gws_memo_messages', type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }

  before do
    site.canonical_domain = "#{unique_id}.example.jp"
    site.save!
  end

  def export_memo(memo)
    visit gws_memo_export_messages_path(site)
    within "form#item-form" do
      select 'eml', from: 'item_format'
      click_on I18n.t("ss.links.select")
    end
    within "#cboxLoadedContent" do
      expect(page).to have_css(".list-item", text: memo.subject)
      click_on memo.subject
    end
    within "form#item-form" do
      perform_enqueued_jobs do
        click_on I18n.t("ss.export")
      end
    end

    expect(page).to have_css("#notice", text: I18n.t("gws/memo/message.notice.start_export"))
    within '#addon-basic' do
      expect(page).to have_content(I18n.t("gws/memo/message.export.start_message").split("\n").first)
    end

    expect(Job::Log.count).to eq 1
    Job::Log.first.tap do |log|
      expect(log.logs).to include(include("INFO -- : Started Job"))
      expect(log.logs).to include(include("INFO -- : Completed Job"))
    end

    page.execute_script("SS.clearNotice();")

    within "nav.user" do
      first(".gws-memo-notice.popup-notice-container a").click

      within ".popup-notice-items .list-item.unseen" do
        click_on I18n.t("gws/memo/message.export.subject")
      end
    end

    within ".gws-memo-notices .body" do
      expect(page).to have_content(I18n.t("gws/memo/message.export.notify_message", link: "").split("\n").first)
      expect(page).to have_link(href: /\.zip$/)
      first("a").click
    end

    wait_for_download

    exported = {}
    Zip::File.open(downloads.first) do |zip_file|
      zip_file.each do |entry|
        name = NKF.nkf("-w", entry.name)
        mail = ::Mail.read_from_string(entry.get_input_stream.read)

        exported[name] = mail
      end
    end

    exported
  end

  describe 'export' do
    before { login_gws_user }

    context "with unseen message" do
      let!(:memo) { create(:gws_memo_message, user: user, site: site) }

      it do
        exported = export_memo(memo)

        expect(exported).to have(1).items
        expect(exported.keys).to include(include(memo.subject))
        exported.values.first.tap do |mail|
          expect(mail.message_id.to_s).to eq "#{memo.id}@#{site.canonical_domain}"
          expect(mail.sender).to be_nil
          expect(mail.date.to_s).to eq memo.created.to_s
          expect(mail[:from].to_s).to eq "#{memo.from.name} <#{memo.from.email}>"
          expect(mail[:to].to_s).to eq memo.to_members.map { |u| "#{u.name} <#{u.email}>" }.join(", ")
          expect(mail[:cc]).to be_nil
          expect(mail[:bcc]).to be_nil
          expect(mail[:reply_to]).to be_nil
          expect(mail["X-Shirasagi-Status"].decoded).to eq "未読"
          expect(mail.in_reply_to).to be_nil
          expect(mail.references).to be_nil
          expect(mail.subject).to eq memo.subject
          expect(mail.mime_type).to eq "text/plain"
          expect(mail.multipart?).to be_falsey
          expect(mail.parts).to be_blank
          expect(mail.body.decoded).to include(memo.text)
        end
      end
    end

    context "with seen message" do
      let!(:memo) { create(:gws_memo_message, user: user, site: site) }

      before do
        memo.set_seen(gws_user).save!
      end

      it do
        exported = export_memo(memo)

        expect(exported).to have(1).items
        expect(exported.keys).to include(include(memo.subject))
        exported.values.first.tap do |mail|
          expect(mail.message_id.to_s).to eq "#{memo.id}@#{site.canonical_domain}"
          expect(mail.sender).to be_nil
          expect(mail.date.to_s).to eq memo.created.to_s
          expect(mail[:from].to_s).to eq "#{memo.from.name} <#{memo.from.email}>"
          expect(mail[:to].to_s).to eq memo.to_members.map { |u| "#{u.name} <#{u.email}>" }.join(", ")
          expect(mail[:cc]).to be_nil
          expect(mail[:bcc]).to be_nil
          expect(mail[:reply_to]).to be_nil
          expect(mail["X-Shirasagi-Status"].decoded).to eq "既読"
          expect(mail.in_reply_to).to be_nil
          expect(mail.references).to be_nil
          expect(mail.subject).to eq memo.subject
          expect(mail.mime_type).to eq "text/plain"
          expect(mail.multipart?).to be_falsey
          expect(mail.parts).to be_blank
          expect(mail.body.decoded).to include(memo.text)
        end
      end
    end

    context "with message which has star" do
      let!(:memo) { create(:gws_memo_message, user: user, site: site) }

      before do
        memo.set_star(gws_user).save!
      end

      it do
        exported = export_memo(memo)

        expect(exported).to have(1).items
        expect(exported.keys).to include(include(memo.subject))
        exported.values.first.tap do |mail|
          expect(mail.message_id.to_s).to eq "#{memo.id}@#{site.canonical_domain}"
          expect(mail.sender).to be_nil
          expect(mail.date.to_s).to eq memo.created.to_s
          expect(mail[:from].to_s).to eq "#{memo.from.name} <#{memo.from.email}>"
          expect(mail[:to].to_s).to eq memo.to_members.map { |u| "#{u.name} <#{u.email}>" }.join(", ")
          expect(mail[:cc]).to be_nil
          expect(mail[:bcc]).to be_nil
          expect(mail[:reply_to]).to be_nil
          expect(mail["X-Shirasagi-Status"].decoded).to eq "未読, スター"
          expect(mail.in_reply_to).to be_nil
          expect(mail.references).to be_nil
          expect(mail.subject).to eq memo.subject
          expect(mail.mime_type).to eq "text/plain"
          expect(mail.multipart?).to be_falsey
          expect(mail.parts).to be_blank
          expect(mail.body.decoded).to include(memo.text)
        end
      end
    end

    context "with html message" do
      let!(:memo) { create(:gws_memo_message, user: user, site: site, format: "html", html: "<p>#{unique_id}</p>") }

      it do
        exported = export_memo(memo)

        expect(exported).to have(1).items
        expect(exported.keys).to include(include(memo.subject))
        exported.values.first.tap do |mail|
          expect(mail.message_id.to_s).to eq "#{memo.id}@#{site.canonical_domain}"
          expect(mail.sender).to be_nil
          expect(mail.date.to_s).to eq memo.created.to_s
          expect(mail[:from].to_s).to eq "#{memo.from.name} <#{memo.from.email}>"
          expect(mail[:to].to_s).to eq memo.to_members.map { |u| "#{u.name} <#{u.email}>" }.join(", ")
          expect(mail[:cc]).to be_nil
          expect(mail[:bcc]).to be_nil
          expect(mail[:reply_to]).to be_nil
          expect(mail["X-Shirasagi-Status"].decoded).to eq "未読"
          expect(mail.in_reply_to).to be_nil
          expect(mail.references).to be_nil
          expect(mail.subject).to eq memo.subject
          expect(mail.mime_type).to eq "text/html"
          expect(mail.multipart?).to be_falsey
          expect(mail.parts).to be_blank
          expect(mail.body.decoded).to include(memo.html)
        end
      end
    end
  end

  context "export messages are only allowed at once per user" do
    let!(:memo) { create(:gws_memo_message, user: user, site: site) }

    before do
      args = [{}]
      Job::Task.create!(
        user_id: gws_user.id, name: SecureRandom.uuid, class_name: "Gws::Memo::MessageExportJob", app_type: "sys",
        pool: "default", args: args, active_job: {
          "job_class" => "Gws::Memo::MessageExportJob", "job_id" => SecureRandom.uuid, "provider_job_id" => nil,
          "queue_name" => "default", "priority" => nil, "arguments" => args
        }
      )

      login_gws_user
    end

    it do
      visit gws_memo_export_messages_path(site)
      within "form#item-form" do
        select 'eml', from: 'item_format'
        click_on I18n.t("ss.links.select")
      end
      within "#cboxLoadedContent" do
        expect(page).to have_css(".list-item", text: memo.subject)
        click_on memo.subject
      end
      within "form#item-form" do
        click_on I18n.t("ss.export")
      end

      expect(page).to have_css("#errorExplanation", text: I18n.t("job.notice.size_limit_exceeded"))

      # export again
      within "form#item-form" do
        select 'eml', from: 'item_format'
        click_on I18n.t("ss.links.select")
      end
      within "#cboxLoadedContent" do
        expect(page).to have_css(".list-item", text: memo.subject)
        click_on memo.subject
      end
      within "form#item-form" do
        click_on I18n.t("ss.export")
      end

      expect(page).to have_css("#errorExplanation", text: I18n.t("job.notice.size_limit_exceeded"))
    end
  end
end
