require 'spec_helper'

describe "gws_memo_message_import_messages", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }

  context "import from zip" do
    let(:user) { gws_user }

    before { login_gws_user }

    it do
      visit gws_memo_import_messages_path(site)

      within "form#item-form" do
        attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/gws/memo/messages.zip"
        click_on I18n.t("ss.import")
      end
      wait_for_notice I18n.t("gws/memo/message.notice.start_import")

      visit gws_memo_messages_path(site)

      expect(page).to have_text("parent")
      expect(page).to have_text("child")
      expect(page).to have_css(".list-item.unseen", count: 5)
      expect(page).to have_css(".folder .unseen", count: 4)
    end
  end

  context "with folders" do
    let!(:user1) { create :gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
    let!(:user2) { create :gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
    let!(:user3) { create :gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
    let!(:user4) { create :gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
    let!(:source_message) do
      build(
        :gws_memo_message, cur_site: site, cur_user: user1, in_to_members: [ user2.id, user3.id, user4.id ]
      )
    end
    let(:user) { user1 }

    before do
      source_message.validate!

      eml_file_path = tmpfile(extname: ".eml", binary: true) do |f|
        source_message.write_as_eml(user, f, site: site)
      end

      zip_file_path = tmpfile(extname: ".zip", binary: true) { |f| f.write '' }
      Zip::File.open(zip_file_path, Zip::File::CREATE) do |zip|
        zip.add(eml_entry_path, eml_file_path)
      end

      Fs::UploadedFile.create_from_file(zip_file_path, content_type: 'application/zip') do |file|
        importer = Gws::Memo::MessageImporter.new(cur_site: site, cur_user: user, in_file: file)
        importer.import_messages
      end

      login_user user
    end

    context 'import files which are right under root folder' do
      let(:eml_entry_path) { "message-1.eml" }

      it do
        visit gws_memo_messages_path(site)
        within ".gws-memo-folder" do
          click_on "no_name"
        end
        within ".gws-memos-index" do
          expect(page).to have_css(".list-item.unseen", count: 1)
          expect(page).to have_css(".list-item.unseen", text: source_message.subject)

          click_on source_message.subject
        end
        within ".gws-memo" do
          expect(page).to have_css(".subject", text: source_message.subject)
          expect(page).to have_css(".from", text: user1.long_name)
          expect(page).to have_css(".date", text: I18n.l(source_message.send_date, format: :picker))
          expect(page).to have_css(".address", text: user2.long_name)
          expect(page).to have_css(".address", text: user3.long_name)
          expect(page).to have_css(".address", text: user4.long_name)
          expect(page).to have_css(".body", text: source_message.text)
        end
        within "#menu" do
          click_on I18n.t("gws/memo/message.links.reply_all")
        end
        within "form#item-form" do
          click_on I18n.t("ss.buttons.draft_save")
        end
        wait_for_notice I18n.t("ss.notice.saved")

        expect(Gws::Memo::Message.all.count).to eq 2
        Gws::Memo::Message.all.where(subject: "Re: #{source_message.subject}").first.tap do |message|
          expect(message.site_id).to eq site.id
          expect(message.send_date).to be_blank
          expect(message.state).to eq "closed"
          expect(message.format).to eq "text"
          # expect(message.text).to include(source_message.text)
          expect(message.from.id).to eq user1.id
          expect(message.from_member_name).to eq user1.long_name
          expect(message.to_member_ids).to have(3).items
          expect(message.to_member_ids).to include(user2.id, user3.id, user4.id)
          expect(message.to_webmail_address_group_ids).to be_blank
          expect(message.to_shared_address_group_ids).to be_blank
          expect(message.to_member_name).to eq [ user2, user3, user4 ].map(&:long_name).join("; ")
          expect(message.cc_member_ids).to be_blank
          expect(message.cc_webmail_address_group_ids).to be_blank
          expect(message.cc_shared_address_group_ids).to be_blank
          expect(message.bcc_member_ids).to be_blank
          expect(message.bcc_webmail_address_group_ids).to be_blank
          expect(message.bcc_shared_address_group_ids).to be_blank
          expect(message.member_ids).to have(3).items
          expect(message.member_ids).to include(user2.id, user3.id, user4.id)
          expect(message.user_settings).to have(3).items
          expect(message.user_settings).to include("user_id" => user2.id, "path" => "INBOX")
          expect(message.user_settings).to include("user_id" => user3.id, "path" => "INBOX")
          expect(message.user_settings).to include("user_id" => user4.id, "path" => "INBOX")
          expect(message.list_message?).to be_falsey
        end
      end
    end

    context 'import files to one of system folders' do
      let(:system_folder) { I18n.t("gws/memo/folder.#{%w(inbox_sent inbox_draft inbox_trash).sample}") }
      let(:eml_entry_path) { "#{system_folder}/message-1.eml" }

      it do
        visit gws_memo_messages_path(site)
        within ".gws-memo-folder" do
          click_on I18n.t('gws/memo/folder.inbox')
        end
        within ".gws-memos-index" do
          expect(page).to have_css(".list-item.unseen", count: 1)
          expect(page).to have_css(".list-item.unseen", text: source_message.subject)

          click_on source_message.subject
        end
        within ".gws-memo" do
          expect(page).to have_css(".subject", text: source_message.subject)
          expect(page).to have_css(".from", text: user1.long_name)
          expect(page).to have_css(".date", text: I18n.l(source_message.send_date, format: :picker))
          expect(page).to have_css(".address", text: user2.long_name)
          expect(page).to have_css(".address", text: user3.long_name)
          expect(page).to have_css(".address", text: user4.long_name)
          expect(page).to have_css(".body", text: source_message.text)
        end
        within "#menu" do
          click_on I18n.t("gws/memo/message.links.reply_all")
        end
        within "form#item-form" do
          click_on I18n.t("ss.buttons.draft_save")
        end
        wait_for_notice I18n.t("ss.notice.saved")

        expect(Gws::Memo::Message.all.count).to eq 2
        Gws::Memo::Message.all.where(subject: "Re: #{source_message.subject}").first.tap do |message|
          expect(message.site_id).to eq site.id
          expect(message.send_date).to be_blank
          expect(message.state).to eq "closed"
          expect(message.format).to eq "text"
          # expect(message.text).to include(source_message.text)
          expect(message.from.id).to eq user1.id
          expect(message.from_member_name).to eq user1.long_name
          expect(message.to_member_ids).to have(3).items
          expect(message.to_member_ids).to include(user2.id, user3.id, user4.id)
          expect(message.to_webmail_address_group_ids).to be_blank
          expect(message.to_shared_address_group_ids).to be_blank
          expect(message.to_member_name).to eq [ user2, user3, user4 ].map(&:long_name).join("; ")
          expect(message.cc_member_ids).to be_blank
          expect(message.cc_webmail_address_group_ids).to be_blank
          expect(message.cc_shared_address_group_ids).to be_blank
          expect(message.bcc_member_ids).to be_blank
          expect(message.bcc_webmail_address_group_ids).to be_blank
          expect(message.bcc_shared_address_group_ids).to be_blank
          expect(message.member_ids).to have(3).items
          expect(message.member_ids).to include(user2.id, user3.id, user4.id)
          expect(message.user_settings).to have(3).items
          expect(message.user_settings).to include("user_id" => user2.id, "path" => "INBOX")
          expect(message.user_settings).to include("user_id" => user3.id, "path" => "INBOX")
          expect(message.user_settings).to include("user_id" => user4.id, "path" => "INBOX")
          expect(message.list_message?).to be_falsey
        end
      end
    end
  end

  # 他サイトのメッセージのインポート
  #
  # 他サイトのメッセージのインポートの場合、同サイトのメッセージのインポートと比較して再現率は低く、
  # 件名、本文などいくつかのデータが読めるだけで、返信しても、宛先が自動で設定されたりはしない。
  context "with other site message" do
    let!(:site1) { create :gws_group }
    let!(:site2) { create :gws_group }
    let!(:role1) { create :gws_role_admin, cur_site: site1 }
    let!(:role2) { create :gws_role_admin, cur_site: site2 }
    let!(:user1) { create :gws_user, cur_site: site1, group_ids: [ site1.id ], gws_role_ids: [ role1.id ] }
    let!(:user2) { create :gws_user, cur_site: site1, group_ids: [ site1.id ], gws_role_ids: [ role1.id ] }
    let!(:user3) { create :gws_user, cur_site: site1, group_ids: [ site1.id ], gws_role_ids: [ role1.id ] }
    let!(:user4) { create :gws_user, cur_site: site1, group_ids: [ site2.id ], gws_role_ids: [ role2.id ] }
    let!(:source_message) do
      build(
        :gws_memo_message, cur_site: site1, cur_user: user1, in_to_members: [ user2.id ], in_cc_members: [ user3.id ]
      )
    end
    let(:eml_entry_path) { "#{I18n.t("gws/memo/folder.inbox")}/message-1.eml" }

    before do
      source_message.validate!

      eml_file_path = tmpfile(extname: ".eml", binary: true) do |f|
        source_message.write_as_eml(user2, f, site: site1)
      end

      zip_file_path = tmpfile(extname: ".zip", binary: true) { |f| f.write '' }
      Zip::File.open(zip_file_path, Zip::File::CREATE) do |zip|
        zip.add(eml_entry_path, eml_file_path)
      end

      Fs::UploadedFile.create_from_file(zip_file_path, content_type: 'application/zip') do |file|
        importer = Gws::Memo::MessageImporter.new(cur_site: site2, cur_user: user4, in_file: file)
        importer.import_messages
      end

      login_user user4
    end

    it do
      visit gws_memo_messages_path(site2)
      within ".gws-memo-folder" do
        click_on I18n.t('gws/memo/folder.inbox')
      end
      within ".gws-memos-index" do
        expect(page).to have_css(".list-item.unseen", count: 1)
        expect(page).to have_css(".list-item.unseen", text: source_message.subject)

        click_on source_message.subject
      end
      within ".gws-memo" do
        expect(page).to have_css(".subject", text: source_message.subject)
        expect(page).to have_css(".from", text: "#{user1.name} <#{user1.email}>")
        expect(page).to have_css(".date", text: I18n.l(source_message.send_date, format: :picker))
        expect(page).to have_no_css(".address")
        expect(page).to have_css(".body", text: source_message.text)
      end
      within "#menu" do
        click_on I18n.t("gws/memo/message.links.reply_all")
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.draft_save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(Gws::Memo::Message.all.count).to eq 2
      Gws::Memo::Message.all.where(subject: "Re: #{source_message.subject}").first.tap do |message|
        expect(message.site_id).to eq site2.id
        expect(message.send_date).to be_blank
        expect(message.state).to eq "closed"
        expect(message.format).to eq "text"
        # expect(message.text).to include(source_message.text)
        expect(message.from.id).to eq user4.id
        expect(message.from_member_name).to eq user4.long_name
        expect(message.to_member_ids).to be_blank
        expect(message.to_webmail_address_group_ids).to be_blank
        expect(message.to_shared_address_group_ids).to be_blank
        expect(message.to_member_name).to be_blank
        expect(message.cc_member_ids).to be_blank
        expect(message.cc_webmail_address_group_ids).to be_blank
        expect(message.cc_shared_address_group_ids).to be_blank
        expect(message.bcc_member_ids).to be_blank
        expect(message.bcc_webmail_address_group_ids).to be_blank
        expect(message.bcc_shared_address_group_ids).to be_blank
        expect(message.member_ids).to be_blank
        expect(message.user_settings).to be_blank
        expect(message.list_message?).to be_falsey
      end
    end
  end
end
