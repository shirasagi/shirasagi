require 'spec_helper'

RSpec.describe Gws::Memo::MessageImporter, type: :model, dbscope: :example do
  let(:site) { gws_site }

  describe "#import_messages" do
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
        importer = described_class.new(cur_site: site, cur_user: user, in_file: file)
        importer.import_messages
      end
    end

    context "with users having email" do
      let!(:user1) { create :gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
      let!(:user2) { create :gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
      let!(:user3) { create :gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
      let!(:user4) { create :gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
      let(:user) { user3 }
      let(:eml_entry_path) { "#{I18n.t('gws/memo/folder.inbox')}/message-1.eml" }

      context "with unread message" do
        let!(:source_message) do
          build(
            :gws_memo_message, cur_site: site, cur_user: user1,
            in_to_members: [ user2.id ], in_cc_members: [ user3.id ], in_bcc_members: [ user4.id ]
          )
        end

        it do
          expect(Gws::Memo::Message.all.count).to eq 1
          Gws::Memo::Message.all.first.tap do |message|
            expect(message.site_id).to eq site.id
            expect(message.state).to eq "public"
            expect(message.subject).to eq source_message.subject
            expect(message.send_date).to eq source_message.created.in_time_zone.change(usec: 0)
            expect(message.format).to eq "text"
            expect(message.text).to include(source_message.text)
            expect(message.from.id).to eq user1.id
            expect(message.from_member_name).to eq user1.long_name
            expect(message.to_member_ids).to have(1).items
            expect(message.to_member_ids).to include(user2.id)
            expect(message.to_webmail_address_group_ids).to be_blank
            expect(message.to_shared_address_group_ids).to be_blank
            expect(message.to_member_name).to eq user2.long_name
            expect(message.cc_member_ids).to have(1).items
            expect(message.cc_member_ids).to include(user3.id)
            expect(message.cc_webmail_address_group_ids).to be_blank
            expect(message.cc_shared_address_group_ids).to be_blank
            expect(message.bcc_member_ids).to be_blank
            expect(message.bcc_webmail_address_group_ids).to be_blank
            expect(message.bcc_shared_address_group_ids).to be_blank
            expect(message.member_ids).to have(1).items
            expect(message.member_ids).to include(user3.id)
            expect(message.user_settings).to have(1).items
            expect(message.user_settings).to include("user_id" => user3.id, "path" => "INBOX")
            expect(message.seen_at(user3)).to be_blank
            expect(message.star?(user3)).to be_falsey
            expect(message.list_message?).to be_falsey
          end

          # 編集した後、user2 のメッセージとして復活しないことを確認
          Gws::Memo::Message.all.first.tap do |message|
            message.subject = unique_id
            message.save!
          end

          Gws::Memo::Message.all.first.tap do |message|
            expect(message.user_settings).to have(1).items
            expect(message.user_settings).to include("user_id" => user3.id, "path" => "INBOX")
          end
        end
      end

      context "with read message" do
        let!(:source_message) do
          message = build(
            :gws_memo_message, cur_site: site, cur_user: user1,
            in_to_members: [ user2.id ], in_cc_members: [ user3.id ], in_bcc_members: [ user4.id ]
          )
          message.validate!
          message.set_seen(user3)
          message
        end

        it do
          expect(Gws::Memo::Message.all.count).to eq 1
          Gws::Memo::Message.all.first.tap do |message|
            # 既読フラグはインポート時に無視される
            expect(message.member_ids).to have(1).items
            expect(message.member_ids).to include(user3.id)
            expect(message.user_settings).to have(1).items
            expect(message.user_settings).to include("user_id" => user3.id, "path" => "INBOX")
            expect(message.seen_at(user3)).to be_blank
            expect(message.star?(user3)).to be_falsey
          end
        end
      end

      context "with started message" do
        let!(:source_message) do
          message = build(
            :gws_memo_message, cur_site: site, cur_user: user1,
            in_to_members: [ user2.id ], in_cc_members: [ user3.id ], in_bcc_members: [ user4.id ]
          )
          message.validate!
          message.set_seen(user3)
          message.set_star(user3)
          message
        end

        it do
          expect(Gws::Memo::Message.all.count).to eq 1
          Gws::Memo::Message.all.first.tap do |message|
            # スターはインポート時に復元される
            expect(message.member_ids).to have(1).items
            expect(message.member_ids).to include(user3.id)
            expect(message.user_settings).to have(1).items
            expect(message.user_settings).to include("user_id" => user3.id, "path" => "INBOX")
            expect(message.seen_at(user3)).to be_blank
            expect(message.star?(user3)).to be_truthy
          end
        end
      end

      context "with folders" do
        let!(:source_message) do
          build(
            :gws_memo_message, cur_site: site, cur_user: user1, in_to_members: [ user2.id, user3.id, user4.id ]
          )
        end

        context "with existing folder" do
          let!(:user2_folder) { create :gws_memo_folder, cur_site: site, cur_user: user2 }
          let(:eml_entry_path) { "#{user2_folder.name}/message-1.eml" }
          let(:user) { user2 }

          it do
            expect(Gws::Memo::Message.all.count).to eq 1
            Gws::Memo::Message.all.first.tap do |message|
              expect(message.member_ids).to have(1).items
              expect(message.member_ids).to include(user2.id)
              expect(message.user_settings).to have(1).items
              expect(message.user_settings).to include("user_id" => user2.id, "path" => user2_folder.id.to_s)
              expect(message.seen_at(user2)).to be_blank
              expect(message.star?(user2)).to be_falsey
            end
          end
        end

        context "with same folder that other user has" do
          let!(:user2_folder) { create :gws_memo_folder, cur_site: site, cur_user: user2 }
          let(:eml_entry_path) { "#{user2_folder.name}/message-1.eml" }
          let(:user) { user3 }

          it do
            # new folder is created
            expect(Gws::Memo::Folder.all.count).to eq 2

            folder = Gws::Memo::Folder.all.where(name: user2_folder.name, user_id: user3.id).first
            expect(folder).to be_present

            expect(Gws::Memo::Message.all.count).to eq 1
            Gws::Memo::Message.all.first.tap do |message|
              expect(message.member_ids).to have(1).items
              expect(message.member_ids).to include(user3.id)
              expect(message.user_settings).to have(1).items
              expect(message.user_settings).to include("user_id" => user3.id, "path" => folder.id.to_s)
              expect(message.seen_at(user3)).to be_blank
              expect(message.star?(user3)).to be_falsey
            end
          end
        end

        context "with non existing folder with sub folders" do
          let(:folder_paths) { Array.new(3) { unique_id } }
          let(:eml_entry_path) { "#{folder_paths.join("/")}/message-1.eml" }
          let(:user) { user4 }

          it do
            # new folder is created
            expect(Gws::Memo::Folder.all.count).to eq 3
            expect(Gws::Memo::Folder.all.where(name: folder_paths.first).first).to be_present
            expect(Gws::Memo::Folder.all.where(name: folder_paths.take(2).join("/")).first).to be_present
            folder = Gws::Memo::Folder.all.where(name: folder_paths.join("/")).first
            expect(folder.site_id).to eq site.id
            expect(folder.name).to eq folder_paths.join("/")
            expect(folder.user_id).to eq user4.id

            expect(Gws::Memo::Message.all.count).to eq 1
            Gws::Memo::Message.all.first.tap do |message|
              expect(message.member_ids).to have(1).items
              expect(message.member_ids).to include(user4.id)
              expect(message.user_settings).to have(1).items
              expect(message.user_settings).to include("user_id" => user4.id, "path" => folder.id.to_s)
              expect(message.seen_at(user4)).to be_blank
              expect(message.star?(user4)).to be_falsey
            end
          end
        end

        context "with root folder" do
          let(:eml_entry_path) { "message-1.eml" }
          let(:user) { user1 }

          it do
            # no name folder is created
            expect(Gws::Memo::Folder.all.count).to eq 1
            folder = Gws::Memo::Folder.all.where(name: "no_name").first
            expect(folder).to be_present

            expect(Gws::Memo::Message.all.count).to eq 1
            Gws::Memo::Message.all.first.tap do |message|
              expect(message.member_ids).to have(1).items
              expect(message.member_ids).to include(user1.id)
              expect(message.user_settings).to have(1).items
              expect(message.user_settings).to include("user_id" => user1.id, "path" => folder.id.to_s)
              expect(message.seen_at(user1)).to be_blank
              expect(message.star?(user1)).to be_falsey
            end
          end
        end
      end
    end

    context "with users having no email" do
      let!(:user1) do
        create :gws_user, email: nil, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids
      end
      let!(:user2) do
        create :gws_user, email: nil, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids
      end
      let!(:user3) do
        create :gws_user, email: nil, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids
      end
      let!(:user4) do
        create :gws_user, email: nil, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids
      end
      let(:user) { user3 }
      let!(:source_message) do
        build(
          :gws_memo_message, cur_site: site, cur_user: user1,
          in_to_members: [ user2.id ], in_cc_members: [ user3.id ], in_bcc_members: [ user4.id ]
        )
      end
      let(:eml_entry_path) { "#{I18n.t('gws/memo/folder.inbox')}/message-1.eml" }

      it do
        expect(Gws::Memo::Message.all.count).to eq 1
        Gws::Memo::Message.all.first.tap do |message|
          expect(message.site_id).to eq site.id
          expect(message.state).to eq "public"
          expect(message.subject).to eq source_message.subject
          expect(message.send_date).to eq source_message.created.in_time_zone.change(usec: 0)
          expect(message.format).to eq "text"
          expect(message.text).to include(source_message.text)
          expect(message.from.id).to eq user1.id
          expect(message.from_member_name).to eq user1.long_name
          expect(message.to_member_ids).to have(1).items
          expect(message.to_member_ids).to include(user2.id)
          expect(message.to_webmail_address_group_ids).to be_blank
          expect(message.to_shared_address_group_ids).to be_blank
          expect(message.to_member_name).to eq user2.long_name
          expect(message.cc_member_ids).to have(1).items
          expect(message.cc_member_ids).to include(user3.id)
          expect(message.cc_webmail_address_group_ids).to be_blank
          expect(message.cc_shared_address_group_ids).to be_blank
          expect(message.bcc_member_ids).to be_blank
          expect(message.bcc_webmail_address_group_ids).to be_blank
          expect(message.bcc_shared_address_group_ids).to be_blank
          expect(message.member_ids).to have(1).items
          expect(message.member_ids).to include(user3.id)
          expect(message.user_settings).to have(1).items
          expect(message.user_settings).to include("user_id" => user3.id, "path" => "INBOX")
          expect(message.seen_at(user3)).to be_blank
          expect(message.star?(user3)).to be_falsey
          expect(message.list_message?).to be_falsey
        end
      end
    end

    context "with attachments" do
      let!(:user1) { create :gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
      let!(:user2) { create :gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
      let!(:user3) { create :gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
      let(:file1) do
        tmp_ss_file cur_user: user1, contents: "#{Rails.root}/spec/fixtures/ss/logo.png", model: "ss/temp_file"
      end
      let(:file2) do
        tmp_ss_file cur_user: user1, contents: "#{Rails.root}/spec/fixtures/ss/shirasagi.pdf", model: "ss/temp_file"
      end
      let(:user) { user2 }
      let(:eml_entry_path) { "#{I18n.t('gws/memo/folder.inbox')}/message-1.eml" }

      context "with text message" do
        let!(:source_message) do
          build(
            :gws_memo_message, cur_site: site, cur_user: user1, in_to_members: [ user2.id, user3.id ],
            file_ids: [ file1.id, file2.id ]
          )
        end

        it do
          expect(Gws::Memo::Message.all.count).to eq 1
          Gws::Memo::Message.all.first.tap do |message|
            expect(message.site_id).to eq site.id
            expect(message.state).to eq "public"
            expect(message.subject).to eq source_message.subject
            expect(message.format).to eq "text"
            expect(message.html).to be_blank
            expect(message.text).to eq source_message.text
            expect(message.from_member_name).to eq user1.long_name
            expect(message.to_member_ids).to have(2).items
            expect(message.to_member_ids).to include(user2.id, user3.id)
            expect(message.member_ids).to have(1).items
            expect(message.member_ids).to include(user2.id)
            expect(message.user_settings).to have(1).items
            expect(message.user_settings).to include("user_id" => user2.id, "path" => "INBOX")
            expect(message.file_ids).to have(2).items
            message.files.each do |file|
              case file.content_type
              when "image/png"
                expect(file.name).to eq file1.name
                expect(file.filename).to eq file1.filename
                expect(file.content_type).to eq file1.content_type
                expect(file.size).to eq file1.size
                expect(Fs.compare_file_head(file.path, file1.path)).to be_truthy
              when "application/pdf"
                expect(file.name).to eq file2.name
                expect(file.filename).to eq file2.filename
                expect(file.content_type).to eq file2.content_type
                expect(file.size).to eq file2.size
                expect(Fs.compare_file_head(file.path, file2.path)).to be_truthy
              end
              expect(file.owner_item_id).to eq message.id
              expect(file.owner_item_type).to eq message.class.name
              expect(file.site_id).to be_blank
            end
          end
        end
      end

      context "with html message" do
        let!(:source_message) do
          build(
            :gws_memo_message, cur_site: site, cur_user: user1, in_to_members: [ user2.id, user3.id ],
            format: "html", text: nil, html: "<p>#{unique_id}</p>",
            file_ids: [ file1.id, file2.id ]
          )
        end

        it do
          expect(Gws::Memo::Message.all.count).to eq 1
          Gws::Memo::Message.all.first.tap do |message|
            expect(message.site_id).to eq site.id
            expect(message.state).to eq "public"
            expect(message.subject).to eq source_message.subject
            expect(message.format).to eq "html"
            expect(message.html).to eq source_message.html
            expect(message.text).to be_blank
            expect(message.from_member_name).to eq user1.long_name
            expect(message.to_member_ids).to have(2).items
            expect(message.to_member_ids).to include(user2.id, user3.id)
            expect(message.member_ids).to have(1).items
            expect(message.member_ids).to include(user2.id)
            expect(message.user_settings).to have(1).items
            expect(message.user_settings).to include("user_id" => user2.id, "path" => "INBOX")
            expect(message.file_ids).to have(2).items
            message.files.each do |file|
              case file.content_type
              when "image/png"
                expect(file.name).to eq file1.name
                expect(file.filename).to eq file1.filename
                expect(file.content_type).to eq file1.content_type
                expect(file.size).to eq file1.size
                expect(Fs.compare_file_head(file.path, file1.path)).to be_truthy
              when "application/pdf"
                expect(file.name).to eq file2.name
                expect(file.filename).to eq file2.filename
                expect(file.content_type).to eq file2.content_type
                expect(file.size).to eq file2.size
                expect(Fs.compare_file_head(file.path, file2.path)).to be_truthy
              end
              expect(file.owner_item_id).to eq message.id
              expect(file.owner_item_type).to eq message.class.name
              expect(file.site_id).to be_blank
            end
          end
        end
      end
    end

    context "with gws/shared_address/group" do
      let(:user1) { create :gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
      let(:user2) { create :gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
      let(:user3) { create :gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
      let(:user) { user3 }
      let!(:shared_address_group1) { create :gws_shared_address_group, order: 10, readable_setting_range: "public" }
      let!(:shared_address1) do
        create(
          :gws_shared_address_address, address_group: shared_address_group1, member: user1, name: user1.name,
          readable_setting_range: "public"
        )
      end
      let!(:shared_address2) do
        create(
          :gws_shared_address_address, address_group: shared_address_group1, member: user2, name: user2.name,
          readable_setting_range: "public"
        )
      end
      let!(:source_message) do
        build(
          :gws_memo_message, cur_site: site, cur_user: user3, in_to_members: [ "shared_group:#{shared_address_group1.id}" ]
        )
      end
      let(:eml_entry_path) { "#{I18n.t('gws/memo/folder.inbox')}/message-1.eml" }

      it do
        expect(Gws::Memo::Message.all.count).to eq 1
        Gws::Memo::Message.all.first.tap do |message|
          expect(message.site_id).to eq site.id
          expect(message.state).to eq "public"
          expect(message.subject).to eq source_message.subject
          expect(message.send_date).to eq source_message.created.in_time_zone.change(usec: 0)
          expect(message.format).to eq "text"
          expect(message.text).to include(source_message.text)
          expect(message.from.id).to eq user3.id
          expect(message.from_member_name).to eq user3.long_name
          expect(message.to_member_ids).to be_blank
          expect(message.to_webmail_address_group_ids).to be_blank
          expect(message.to_shared_address_group_ids).to have(1).items
          expect(message.to_shared_address_group_ids).to include(shared_address_group1.id)
          expect(message.to_member_name).to eq shared_address_group1.name
          expect(message.cc_member_ids).to be_blank
          expect(message.cc_webmail_address_group_ids).to be_blank
          expect(message.cc_shared_address_group_ids).to be_blank
          expect(message.bcc_member_ids).to be_blank
          expect(message.bcc_webmail_address_group_ids).to be_blank
          expect(message.bcc_shared_address_group_ids).to be_blank
          expect(message.member_ids).to have(1).items
          expect(message.member_ids).to include(user3.id)
          expect(message.user_settings).to have(1).items
          expect(message.user_settings).to include("user_id" => user3.id, "path" => "INBOX")
          expect(message.seen_at(user3)).to be_blank
          expect(message.star?(user3)).to be_falsey
          expect(message.list_message?).to be_falsey
        end
      end
    end

    context "with webmail/address_group" do
      let(:user1) { create :gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
      let(:user2) { create :gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
      let(:user3) { create :gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
      let(:user) { user1 }
      let!(:address_group1) { create :webmail_address_group, cur_user: user1 }
      let!(:address1) do
        create :webmail_address, cur_user: user1, address_group: address_group1, member: user2, name: user2.name
      end
      let!(:address2) do
        create :webmail_address, cur_user: user1, address_group: address_group1, member: user3, name: user3.name
      end
      let!(:source_message) do
        build(
          :gws_memo_message, cur_site: site, cur_user: user1, in_to_members: [ "webmail_group:#{address_group1.id}" ]
        )
      end
      let(:eml_entry_path) { "#{I18n.t('gws/memo/folder.inbox')}/message-1.eml" }

      it do
        expect(Gws::Memo::Message.all.count).to eq 1
        Gws::Memo::Message.all.first.tap do |message|
          expect(message.site_id).to eq site.id
          expect(message.state).to eq "public"
          expect(message.subject).to eq source_message.subject
          expect(message.send_date).to eq source_message.created.in_time_zone.change(usec: 0)
          expect(message.format).to eq "text"
          expect(message.text).to include(source_message.text)
          expect(message.from.id).to eq user1.id
          expect(message.from_member_name).to eq user1.long_name
          expect(message.to_member_ids).to be_blank
          expect(message.to_webmail_address_group_ids).to have(1).items
          expect(message.to_webmail_address_group_ids).to include(address_group1.id)
          expect(message.to_shared_address_group_ids).to be_blank
          expect(message.to_member_name).to eq address_group1.name
          expect(message.cc_member_ids).to be_blank
          expect(message.cc_webmail_address_group_ids).to be_blank
          expect(message.cc_shared_address_group_ids).to be_blank
          expect(message.bcc_member_ids).to be_blank
          expect(message.bcc_webmail_address_group_ids).to be_blank
          expect(message.bcc_shared_address_group_ids).to be_blank
          expect(message.member_ids).to have(1).items
          expect(message.member_ids).to include(user1.id)
          expect(message.user_settings).to have(1).items
          expect(message.user_settings).to include("user_id" => user1.id, "path" => "INBOX")
          expect(message.seen_at(user3)).to be_blank
          expect(message.star?(user3)).to be_falsey
          expect(message.list_message?).to be_falsey
        end
      end
    end

    context "with list message" do
      let(:user1) { create :gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
      let(:user2) { create :gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
      let(:user3) { create :gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
      let(:user) { user3 }
      let!(:list) { create :gws_memo_list, cur_site: site, member_ids: [ user2.id, user3.id ] }
      let!(:source_message) do
        build(
          :gws_memo_list_message, cur_user: user1, cur_site: site,
          list: list, from_member_name: list.sender_name, member_ids: list.overall_members.map(&:id),
          in_validate_presence_member: true, in_append_signature: true, in_skip_validates_sender_quota: true,
          state: "public"
        )
      end
      let(:eml_entry_path) { "#{I18n.t('gws/memo/folder.inbox')}/message-1.eml" }

      it do
        expect(Gws::Memo::ListMessage.all.count).to eq 1
        Gws::Memo::ListMessage.all.first.tap do |message|
          expect(message.site_id).to eq site.id
          expect(message.state).to eq "public"
          expect(message.subject).to eq source_message.subject
          expect(message.send_date).to eq source_message.created.in_time_zone.change(usec: 0)
          expect(message.format).to eq "text"
          expect(message.text).to include(source_message.text)
          # expect(message.from).to be_blank
          expect(message.from_member_name).to eq list.sender_name
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
          expect(message.member_ids).to have(1).items
          expect(message.member_ids).to include(user3.id)
          expect(message.user_settings).to have(1).items
          expect(message.user_settings).to include("user_id" => user3.id, "path" => "INBOX")
          expect(message.seen_at(user3)).to be_blank
          expect(message.star?(user3)).to be_falsey
          expect(message.list_message?).to be_truthy
          expect(message.list_id).to eq list.id
        end
      end
    end
  end

  context "import from zip" do
    let(:user) { gws_user }
    let(:zip_file_path) { "#{Rails.root}/spec/fixtures/gws/memo/messages.zip" }
    let!(:file) { Fs::UploadedFile.create_from_file(zip_file_path, content_type: 'application/zip') }

    it do
      importer = described_class.new(cur_site: site, cur_user: user, in_file: file)
      importer.import_messages

      expect(Gws::Memo::Message.all.count).to eq 8
      Gws::Memo::Message.all.find_by(subject: "宛先　→ 共有アドレスメッセージ").tap do |message|
        expect(message.site_id).to eq site.id
        expect(message.state).to eq "public"
        expect(message.send_date).to eq "Tue, 26 Oct 2021 19:45:32 +0900".in_time_zone
        expect(message.format).to eq "text"
        expect(message.text).to include("宛先　→ 共有アドレスメッセージ")
        expect(message.from).to be_blank
        expect(message.from_member_name).to eq "\"システム管理者\" <sys@example.jp>"
        expect(message.to_member_ids).to be_blank
        # expect(message.to_member_name).to eq "gws-sys (sys); gw-admin (admin)"
        expect(message.to_member_name).to be_blank
        expect(message.cc_member_ids).to be_blank
        expect(message.bcc_member_ids).to be_blank
        expect(message.member_ids).to have(1).items
        expect(message.member_ids).to include(user.id)
        expect(message.user_settings).to have(1).items
        expect(message.user_settings).to include("user_id" => user.id, path: "INBOX")
      end
      Gws::Memo::Message.all.find_by(subject: "宛先に高橋、伊藤　ccにサイト管理者").tap do |message|
        expect(message.site_id).to eq site.id
        expect(message.state).to eq "public"
        expect(message.send_date).to eq "Tue, 26 Oct 2021 19:45:32 +0900".in_time_zone
        expect(message.format).to eq "text"
        expect(message.text).to include("宛先に高橋、伊藤　ccにサイト管理者")
        expect(message.from).to be_blank
        expect(message.from_member_name).to eq "\"伊藤 幸子\" <user4@example.jp>"
        expect(message.to_member_ids).to be_blank
        # expect(message.to_member_name).to eq "gw-admin (admin)"
        expect(message.to_member_name).to be_blank
        expect(message.cc_member_ids).to be_blank
        expect(message.bcc_member_ids).to be_blank
        expect(message.member_ids).to have(1).items
        expect(message.member_ids).to include(user.id)
        expect(message.user_settings).to have(1).items
        expect(message.user_settings).to include("user_id" => user.id, path: "INBOX")
      end
      Gws::Memo::Message.all.find_by(subject: "権限MAXノヒトタチヘ").tap do |message|
        expect(message.site_id).to eq site.id
        expect(message.state).to eq "public"
        expect(message.send_date).to eq "Tue, 26 Oct 2021 19:45:32 +0900".in_time_zone
        expect(message.format).to eq "text"
        expect(message.text).to include("テスト")
        expect(message.from).to be_blank
        expect(message.from_member_name).to eq "\"高橋 清\" <user5@example.jp>"
        expect(message.to_member_ids).to be_blank
        # expect(message.to_member_name).to eq "gw-admin (admin)"
        expect(message.to_member_name).to be_blank
        expect(message.cc_member_ids).to be_blank
        expect(message.bcc_member_ids).to be_blank
        expect(message.member_ids).to have(1).items
        expect(message.member_ids).to include(user.id)
        expect(message.user_settings).to have(1).items
        expect(message.user_settings).to include("user_id" => user.id, path: "INBOX")
      end
      Gws::Memo::Message.all.find_by(subject: "adminさんへのメッセージ").tap do |message|
        expect(message.site_id).to eq site.id
        expect(message.state).to eq "public"
        expect(message.send_date).to eq "Tue, 26 Oct 2021 19:45:32 +0900".in_time_zone
        expect(message.format).to eq "text"
        expect(message.text).to include("adminさんへのメッセージ本文")
        expect(message.from).to be_blank
        expect(message.from_member_name).to eq "\"渡辺 和子\" <user2@example.jp>"
        expect(message.to_member_ids).to be_blank
        # expect(message.to_member_name).to eq "gw-admin (admin); gws-sys (sys)"
        expect(message.to_member_name).to be_blank
        expect(message.cc_member_ids).to be_blank
        expect(message.bcc_member_ids).to be_blank
        expect(message.member_ids).to have(1).items
        expect(message.member_ids).to include(user.id)
        expect(message.user_settings).to have(1).items
        expect(message.user_settings).to include("user_id" => user.id, path: "INBOX")
      end
      Gws::Memo::Message.all.find_by(subject: "システム管理者とサイト管理者").tap do |message|
        expect(message.site_id).to eq site.id
        expect(message.state).to eq "public"
        expect(message.send_date).to eq "Tue, 26 Oct 2021 19:45:31 +0900".in_time_zone
        expect(message.format).to eq "text"
        expect(message.text).to include("システム管理者とサイト管理者")
        expect(message.from).to be_blank
        expect(message.from_member_name).to eq "\"鈴木 茂\" <user1@example.jp>"
        expect(message.to_member_ids).to be_blank
        # expect(message.to_member_name).to eq "gw-admin (admin); gws-sys (sys)"
        expect(message.to_member_name).to be_blank
        expect(message.cc_member_ids).to be_blank
        expect(message.bcc_member_ids).to be_blank
        expect(message.member_ids).to have(1).items
        expect(message.member_ids).to include(user.id)
        expect(message.user_settings).to have(1).items
        expect(message.user_settings).to include("user_id" => user.id, path: "INBOX")
      end
      Gws::Memo::Message.all.find_by(subject: "parentフォルダー").tap do |message|
        expect(message.site_id).to eq site.id
        expect(message.state).to eq "public"
        expect(message.send_date).to eq "Tue, 26 Oct 2021 19:45:32 +0900".in_time_zone
        expect(message.format).to eq "text"
        expect(message.text).to be_blank
        expect(message.from).to be_blank
        expect(message.from_member_name).to eq "\"システム管理者\" <sys@example.jp>"
        expect(message.to_member_ids).to be_blank
        # expect(message.to_member_name).to eq "gws-sys (sys); gw-admin (admin)"
        expect(message.to_member_name).to be_blank
        expect(message.cc_member_ids).to be_blank
        expect(message.bcc_member_ids).to be_blank
        expect(message.member_ids).to have(1).items
        expect(message.member_ids).to include(user.id)
        expect(message.user_settings).to have(1).items
        folder = Gws::Memo::Folder.find_by(name: "parent")
        expect(message.user_settings).to include("user_id" => user.id, path: folder.id.to_s)
      end
      Gws::Memo::Message.all.find_by(subject: "childフォルダー").tap do |message|
        expect(message.site_id).to eq site.id
        expect(message.state).to eq "public"
        expect(message.send_date).to eq "Tue, 26 Oct 2021 19:45:32 +0900".in_time_zone
        expect(message.format).to eq "text"
        expect(message.text).to be_blank
        expect(message.from).to be_blank
        expect(message.from_member_name).to eq "\"システム管理者\" <sys@example.jp>"
        expect(message.to_member_ids).to be_blank
        # expect(message.to_member_name).to eq "gws-sys (sys); gw-admin (admin)"
        expect(message.to_member_name).to be_blank
        expect(message.cc_member_ids).to be_blank
        expect(message.bcc_member_ids).to be_blank
        expect(message.member_ids).to have(1).items
        expect(message.member_ids).to include(user.id)
        expect(message.user_settings).to have(1).items
        folder = Gws::Memo::Folder.find_by(name: "parent/child")
        expect(message.user_settings).to include("user_id" => user.id, path: folder.id.to_s)
      end
      Gws::Memo::Message.all.find_by(subject: "grandchildフォルダー").tap do |message|
        expect(message.site_id).to eq site.id
        expect(message.state).to eq "public"
        expect(message.send_date).to eq "Tue, 26 Oct 2021 19:45:32 +0900".in_time_zone
        expect(message.format).to eq "text"
        expect(message.text).to be_blank
        expect(message.from).to be_blank
        expect(message.from_member_name).to eq "\"システム管理者\" <sys@example.jp>"
        expect(message.to_member_ids).to be_blank
        # expect(message.to_member_name).to eq "gws-sys (sys); gw-admin (admin)"
        expect(message.to_member_name).to be_blank
        expect(message.cc_member_ids).to be_blank
        expect(message.bcc_member_ids).to be_blank
        expect(message.member_ids).to have(1).items
        expect(message.member_ids).to include(user.id)
        expect(message.user_settings).to have(1).items
        folder = Gws::Memo::Folder.find_by(name: "parent/child/grandchild")
        expect(message.user_settings).to include("user_id" => user.id, path: folder.id.to_s)

        expect(message.file_ids).to have(1).items
        message.files.first.tap do |file|
          expect(file.name).to eq "img3.jpg"
          expect(file.filename).to eq "img3.jpg"
          expect(file.content_type).to eq "image/jpeg"
          expect(file.size).to eq 725
          expect(file.image?).to be_truthy
          expect(file.image_dimension).to eq [ 712, 475 ]
          expect(file.owner_item_id).to eq message.id
          expect(file.owner_item_type).to eq message.class.name
          expect(file.site_id).to be_blank
        end
      end
    end
  end

  context "when to, cc and bcc are empty" do
    let(:user) { gws_user }
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
        expect(message.state).to eq "public"
        expect(message.subject).to eq "622592292742916363836bd4"
        expect(message.send_date).to eq "Mon, 07 Mar 2022 14:03:19 +0900".in_time_zone
        expect(message.format).to eq "text"
        expect(message.text).to include("こんにちは")
        expect(message.from).to be_blank
        expect(message.from_member_name).to eq "Mailing List <list@example.jp>"
        expect(message.to_member_ids).to be_blank
        expect(message.to_member_name).to be_blank
        expect(message.cc_member_ids).to be_blank
        expect(message.bcc_member_ids).to be_blank
        expect(message.member_ids).to have(1).items
        expect(message.member_ids).to include(user.id)
        expect(message.user_settings).to have(1).items
        expect(message.user_settings).to include("user_id" => user.id, path: "INBOX")
      end
    end
  end

  context "with multipart/alternative" do
    let(:user) { gws_user }
    let(:eml_file_path) { "#{Rails.root}/spec/fixtures/gws/memo/multipart_alternative.eml" }
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
        expect(message.state).to eq "public"
        expect(message.subject).to eq "subject-i61192207c8"
        expect(message.send_date).to eq "Fri, 13 May 2022 15:26:26 +0900".in_time_zone
        expect(message.format).to eq "text"
        expect(message.text).to eq "m55ee4e7dbe"
        expect(message.from).to be_blank
        expect(message.from_member_name).to eq "name-l1e3db2852e <uid-p1e4dc2a870@example.jp>"
        expect(message.to_member_ids).to be_blank
        expect(message.to_member_name).to be_blank
        expect(message.cc_member_ids).to be_blank
        expect(message.bcc_member_ids).to be_blank
        expect(message.member_ids).to have(1).items
        expect(message.member_ids).to include(user.id)
        expect(message.user_settings).to have(1).items
        expect(message.user_settings).to include("user_id" => user.id, path: "INBOX")
        expect(message.file_ids).to have(1).items
        message.files.first.tap do |file|
          expect(file.name).to eq "no_name"
          expect(file.filename).to eq "no_name"
          expect(file.content_type).to eq "application/octet-stream"
          expect(file.size).to be > 0
          expect(File.read(message.files.first.path)).to eq "<p>#{message.text}</p>"
        end
      end
    end
  end
end
