require 'spec_helper'

RSpec.describe Gws::Memo::MessageImporter, type: :model, dbscope: :example do
  let(:site) { gws_site }
  let(:user) { gws_user }

  context "when to, cc and bcc are empty" do
    let(:eml_file_path) { "#{Rails.root}/spec/fixtures/gws/memo/message-1.eml" }
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
        expect(message.to_member_ids).to have(1).items
        expect(message.to_member_ids).to include(user.id)
        expect(message.cc_member_ids).to be_blank
        expect(message.bcc_member_ids).to be_blank
        expect(message.member_ids).to have(1).items
        expect(message.member_ids).to include(user.id)
        expect(message.user_settings).to include("user_id" => user.id, path: "INBOX")
      end
    end
  end
end
