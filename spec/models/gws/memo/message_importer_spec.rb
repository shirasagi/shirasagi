require 'spec_helper'

RSpec.describe Gws::Memo::MessageImporter, type: :model, dbscope: :example do
  let(:site) { gws_site }
  let(:user) { gws_user }

  context "import from zip" do
    let(:zip_file_path) { "#{Rails.root}/spec/fixtures/gws/memo/messages.zip" }
    let!(:file) { Fs::UploadedFile.create_from_file(zip_file_path, content_type: 'application/zip') }

    it do
      importer = described_class.new(cur_site: site, cur_user: user, in_file: file)
      importer.import_messages

      expect(Gws::Memo::Message.all.count).to eq 8
      Gws::Memo::Message.all.find_by(subject: "宛先　→ 共有アドレスメッセージ").tap do |message|
        expect(message.site_id).to eq site.id
        expect(message.send_date).to eq "Tue, 26 Oct 2021 19:45:32 +0900".in_time_zone
        expect(message.format).to eq "text"
        expect(message.text).to include("宛先　→ 共有アドレスメッセージ")
        expect(message.from.id).to eq gws_sys_user.id
        expect(message.from_member_name).to eq "gws-sys (sys)"
        expect(message.to_member_ids).to have(2).items
        expect(message.to_member_ids).to include(user.id, gws_sys_user.id)
        expect(message.to_member_name).to eq "gws-sys (sys); gw-admin (admin)"
        expect(message.cc_member_ids).to be_blank
        expect(message.bcc_member_ids).to be_blank
        expect(message.member_ids).to have(1).items
        expect(message.member_ids).to include(user.id)
        expect(message.user_settings).to include("user_id" => user.id, path: "INBOX")
      end
      Gws::Memo::Message.all.find_by(subject: "宛先に高橋、伊藤　ccにサイト管理者").tap do |message|
        expect(message.site_id).to eq site.id
        expect(message.send_date).to eq "Tue, 26 Oct 2021 19:45:32 +0900".in_time_zone
        expect(message.format).to eq "text"
        expect(message.text).to include("宛先に高橋、伊藤　ccにサイト管理者")
        expect(message.from.id).to eq user.id
        expect(message.from_member_name).to eq "gw-admin (admin)"
        expect(message.to_member_ids).to have(1).items
        expect(message.to_member_ids).to include(user.id)
        expect(message.to_member_name).to eq "gw-admin (admin)"
        expect(message.cc_member_ids).to have(1).items
        expect(message.cc_member_ids).to include(gws_sys_user.id)
        expect(message.bcc_member_ids).to be_blank
        expect(message.member_ids).to have(1).items
        expect(message.member_ids).to include(user.id)
        expect(message.user_settings).to include("user_id" => user.id, path: "INBOX")
      end
      Gws::Memo::Message.all.find_by(subject: "権限MAXノヒトタチヘ").tap do |message|
        expect(message.site_id).to eq site.id
        expect(message.send_date).to eq "Tue, 26 Oct 2021 19:45:32 +0900".in_time_zone
        expect(message.format).to eq "text"
        expect(message.text).to include("テスト")
        expect(message.from.id).to eq user.id
        expect(message.from_member_name).to eq "gw-admin (admin)"
        expect(message.to_member_ids).to have(1).items
        expect(message.to_member_ids).to include(user.id)
        expect(message.to_member_name).to eq "gw-admin (admin)"
        expect(message.cc_member_ids).to have(2).items
        expect(message.cc_member_ids).to include(user.id, gws_sys_user.id)
        expect(message.bcc_member_ids).to be_blank
        expect(message.member_ids).to have(1).items
        expect(message.member_ids).to include(user.id)
        expect(message.user_settings).to include("user_id" => user.id, path: "INBOX")
      end
      Gws::Memo::Message.all.find_by(subject: "adminさんへのメッセージ").tap do |message|
        expect(message.site_id).to eq site.id
        expect(message.send_date).to eq "Tue, 26 Oct 2021 19:45:32 +0900".in_time_zone
        expect(message.format).to eq "text"
        expect(message.text).to include("adminさんへのメッセージ本文")
        expect(message.from.id).to eq user.id
        expect(message.from_member_name).to eq "gw-admin (admin)"
        expect(message.to_member_ids).to have(2).items
        expect(message.to_member_ids).to include(user.id, gws_sys_user.id)
        expect(message.to_member_name).to eq "gw-admin (admin); gws-sys (sys)"
        expect(message.cc_member_ids).to be_blank
        expect(message.bcc_member_ids).to be_blank
        expect(message.member_ids).to have(1).items
        expect(message.member_ids).to include(user.id)
        expect(message.user_settings).to include("user_id" => user.id, path: "INBOX")
      end
      Gws::Memo::Message.all.find_by(subject: "システム管理者とサイト管理者").tap do |message|
        expect(message.site_id).to eq site.id
        expect(message.send_date).to eq "Tue, 26 Oct 2021 19:45:31 +0900".in_time_zone
        expect(message.format).to eq "text"
        expect(message.text).to include("システム管理者とサイト管理者")
        expect(message.from.id).to eq user.id
        expect(message.from_member_name).to eq "gw-admin (admin)"
        expect(message.to_member_ids).to have(2).items
        expect(message.to_member_ids).to include(user.id, gws_sys_user.id)
        expect(message.to_member_name).to eq "gw-admin (admin); gws-sys (sys)"
        expect(message.cc_member_ids).to be_blank
        expect(message.bcc_member_ids).to be_blank
        expect(message.member_ids).to have(1).items
        expect(message.member_ids).to include(user.id)
        expect(message.user_settings).to include("user_id" => user.id, path: "INBOX")
      end
      Gws::Memo::Message.all.find_by(subject: "parentフォルダー").tap do |message|
        expect(message.site_id).to eq site.id
        expect(message.send_date).to eq "Tue, 26 Oct 2021 19:45:32 +0900".in_time_zone
        expect(message.format).to eq "text"
        expect(message.text).to be_blank
        expect(message.from.id).to eq gws_sys_user.id
        expect(message.from_member_name).to eq "gws-sys (sys)"
        expect(message.to_member_ids).to have(2).items
        expect(message.to_member_ids).to include(user.id, gws_sys_user.id)
        expect(message.to_member_name).to eq "gws-sys (sys); gw-admin (admin)"
        expect(message.cc_member_ids).to be_blank
        expect(message.bcc_member_ids).to be_blank
        expect(message.member_ids).to have(1).items
        expect(message.member_ids).to include(user.id)
        folder = Gws::Memo::Folder.find_by(name: "parent")
        expect(message.user_settings).to include("user_id" => user.id, path: folder.id.to_s)
      end
      Gws::Memo::Message.all.find_by(subject: "childフォルダー").tap do |message|
        expect(message.site_id).to eq site.id
        expect(message.send_date).to eq "Tue, 26 Oct 2021 19:45:32 +0900".in_time_zone
        expect(message.format).to eq "text"
        expect(message.text).to be_blank
        expect(message.from.id).to eq gws_sys_user.id
        expect(message.from_member_name).to eq "gws-sys (sys)"
        expect(message.to_member_ids).to have(2).items
        expect(message.to_member_ids).to include(user.id, gws_sys_user.id)
        expect(message.to_member_name).to eq "gws-sys (sys); gw-admin (admin)"
        expect(message.cc_member_ids).to be_blank
        expect(message.bcc_member_ids).to be_blank
        expect(message.member_ids).to have(1).items
        expect(message.member_ids).to include(user.id)
        folder = Gws::Memo::Folder.find_by(name: "parent/child")
        expect(message.user_settings).to include("user_id" => user.id, path: folder.id.to_s)
      end
      Gws::Memo::Message.all.find_by(subject: "grandchildフォルダー").tap do |message|
        expect(message.site_id).to eq site.id
        expect(message.send_date).to eq "Tue, 26 Oct 2021 19:45:32 +0900".in_time_zone
        expect(message.format).to eq "text"
        expect(message.text).to be_blank
        expect(message.from.id).to eq gws_sys_user.id
        expect(message.from_member_name).to eq "gws-sys (sys)"
        expect(message.to_member_ids).to have(2).items
        expect(message.to_member_ids).to include(user.id, gws_sys_user.id)
        expect(message.to_member_name).to eq "gws-sys (sys); gw-admin (admin)"
        expect(message.cc_member_ids).to be_blank
        expect(message.bcc_member_ids).to be_blank
        expect(message.member_ids).to have(1).items
        expect(message.member_ids).to include(user.id)
        folder = Gws::Memo::Folder.find_by(name: "parent/child/grandchild")
        expect(message.user_settings).to include("user_id" => user.id, path: folder.id.to_s)
      end
    end
  end

  context "when to, cc and bcc are empty" do
    let(:eml_file_path) { "#{Rails.root}/spec/fixtures/gws/memo/old-list-message-1.eml" }
    let(:eml_entry_path) { "#{I18n.t('gws/memo/folder.inbox')}/message-1.eml" }
    let(:zip_file_path) do
      path = tmpfile(extname: ".zip", binary: true) { |f| f.write '' }
      Zip.unicode_names = true
      Zip::File.open(path, Zip::File::CREATE) do |zip|
        zip.add(eml_entry_path, eml_file_path)
      end
      path
    end
    let!(:file) { Fs::UploadedFile.create_from_file(zip_file_path, content_type: 'application/zip') }

    it do
      importer = described_class.new(cur_site: site, cur_user: user, in_file: file)
      importer.import_messages

      expect(Gws::Memo::Message.all.count).to eq 1
      Gws::Memo::Message.all.first.tap do |message|
        expect(message.site_id).to eq site.id
        expect(message.subject).to eq "622592292742916363836bd4"
        expect(message.send_date).to eq "Mon, 07 Mar 2022 14:03:19 +0900".in_time_zone
        expect(message.format).to eq "text"
        expect(message.text).to include("こんにちは")
        expect(message.from.id).to eq user.id
        expect(message.from_member_name).to eq "Mailing List"
        expect(message.to_member_ids).to have(1).items
        expect(message.to_member_ids).to include(user.id)
        expect(message.to_member_name).to be_blank
        expect(message.cc_member_ids).to be_blank
        expect(message.bcc_member_ids).to be_blank
        expect(message.member_ids).to have(1).items
        expect(message.member_ids).to include(user.id)
        expect(message.user_settings).to include("user_id" => user.id, path: "INBOX")
      end
    end
  end
end
