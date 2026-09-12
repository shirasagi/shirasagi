require 'spec_helper'

describe "webmail_mails", type: :feature, dbscope: :example, imap: true, js: true do
  let!(:user) { webmail_imap }
  let!(:folder_name1) { "処理状況" }
  let!(:filter1) do
    create(
      :webmail_filter, cur_user: user, state: "enabled", order: 0,
      action: "move", mailbox: Net::IMAP.encode_utf7("INBOX.#{folder_name1}"),
      conjunction: "or", conditions: [{ field: "subject", operator: "include", value: "処理状況" }]
    )
  end
  let(:subject) { "処理状況 (1/2)" }

  before do
    webmail_create_folder(user, "INBOX.#{folder_name1}")
    webmail_import_mail(user, message)

    ActionMailer::Base.deliveries.clear
    login_user(user)
  end

  after do
    webmail_delete_folder(user, "INBOX.#{folder_name1}")

    ActionMailer::Base.deliveries.clear
  end

  shared_examples "a mail with japanese subject should be filtered" do
    it do
      visit webmail_mails_path(account: 0)
      expect(page).to have_css(".list-item", count: 0)

      click_on folder_name1[0..8]
      expect(page).to have_css(".list-item", count: 1)
    end
  end

  context "ss-4612: https://github.com/shirasagi/shirasagi/issues/4612" do
    context "with plain 8-bit UTF-8" do
      let(:message) do
        <<~MSG
          Date: #{Time.zone.now.rfc2822}
          From: #{unique_email}
          To: #{user.imap_settings[0][:imap_account]}
          Message-ID: <#{SecureRandom.uuid}@example.jp.mail>
          Subject: #{subject}
          Mime-Version: 1.0
          Content-Type: text/plain; charset=UTF-8
          Content-Transfer-Encoding: base64

          #{Base64.encode64(ss_japanese_text)}
        MSG
      end

      it_behaves_like "a mail with japanese subject should be filtered"
    end

    context "with base64 UTF-8" do
      let(:encoded_subject) do
        encoded = Base64.strict_encode64(subject).sub(/=+$/, '')
        "Subject: =?UTF-8?B?#{encoded}?="
      end
      let(:message) do
        <<~MSG
          Date: #{Time.zone.now.rfc2822}
          From: #{unique_email}
          To: #{user.imap_settings[0][:imap_account]}
          Message-ID: <#{SecureRandom.uuid}@example.jp.mail>
          #{encoded_subject}
          Mime-Version: 1.0
          Content-Type: text/plain; charset=UTF-8
          Content-Transfer-Encoding: base64

          #{Base64.encode64(ss_japanese_text)}
        MSG
      end

      before do
        expect(message).to include("=?UTF-8?B?")
      end

      it_behaves_like "a mail with japanese subject should be filtered"
    end

    context "with quoted printable UTF-8" do
      let(:encoded_subject) do
        Mail::SubjectField.new(subject).encoded
      end
      let(:message) do
        <<~MSG
          Date: #{Time.zone.now.rfc2822}
          From: #{unique_email}
          To: #{user.imap_settings[0][:imap_account]}
          Message-ID: <#{SecureRandom.uuid}@example.jp.mail>
          #{encoded_subject}
          Mime-Version: 1.0
          Content-Type: text/plain; charset=UTF-8
          Content-Transfer-Encoding: base64

          #{Base64.encode64(ss_japanese_text)}
        MSG
      end

      before do
        expect(message).to include("=?UTF-8?Q?")
      end

      it_behaves_like "a mail with japanese subject should be filtered"
    end

    context "with base64 ISO-2022-JP" do
      let(:encoded_subject) do
        Mail::SubjectField.new(subject, "iso-2022-jp").encoded
      end
      let(:message) do
        <<~MSG
          Date: #{Time.zone.now.rfc2822}
          From: #{unique_email}
          To: #{user.imap_settings[0][:imap_account]}
          Message-ID: <#{SecureRandom.uuid}@example.jp.mail>
          #{encoded_subject}
          Mime-Version: 1.0
          Content-Type: text/plain; charset=UTF-8
          Content-Transfer-Encoding: base64

          #{Base64.encode64(ss_japanese_text)}
        MSG
      end

      before do
        expect(message).to include("=?ISO-2022-JP?B?")
      end

      it_behaves_like "a mail with japanese subject should be filtered"
    end

    context "with quoted printable ISO-2022-JP" do
      let(:encoded_subject) do
        encoded = Mail.encoding_to_charset(Mail::Preprocessor.process(subject), "ISO-2022-JP")
        encoded.force_encoding(Encoding::ASCII_8BIT)
        quoted_printable = [ encoded ].pack("M").gsub("=\n", "")
        "Subject: =?ISO-2022-JP?Q?#{quoted_printable}?="
      end
      let(:message) do
        <<~MSG
          Date: #{Time.zone.now.rfc2822}
          From: #{unique_email}
          To: #{user.imap_settings[0][:imap_account]}
          Message-ID: <#{SecureRandom.uuid}@example.jp.mail>
          #{encoded_subject}
          Mime-Version: 1.0
          Content-Type: text/plain; charset=UTF-8
          Content-Transfer-Encoding: base64

          #{Base64.encode64(ss_japanese_text)}
        MSG
      end

      before do
        expect(message).to include("=?ISO-2022-JP?Q?")
      end

      it_behaves_like "a mail with japanese subject should be filtered"
    end
  end
end
