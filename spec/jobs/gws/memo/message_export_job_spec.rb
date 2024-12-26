require 'spec_helper'

describe Gws::Memo::MessageExportJob, dbscope: :example do
  let(:site) { gws_site }
  let(:canonical_domain) { site.canonical_domain.presence || SS.config.gws.canonical_domain }
  let(:root_url) do
    scheme = site.canonical_scheme.presence || SS.config.gws.canonical_scheme.presence || "http"
    domain = canonical_domain
    "#{scheme}://#{domain}"
  end
  let(:export_message) do
    proc do
      job = Gws::Memo::MessageExportJob.new([ message.id.to_s ], root_url: root_url, export_filter: "selected")
      job = job.bind("site_id" => site.id, "user_id" => user3.id)
      job.perform_now

      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      zip_creator = job.instance_variable_get(:@output_zip)
      expect(File.size(zip_creator.path)).to be > 0

      @exported = {}
      Zip::File.open(zip_creator.path) do |zip_file|
        zip_file.each do |entry|
          name = NKF.nkf("-w", entry.name)
          content = entry.get_input_stream.read
          mail = Mail.read_from_string(content)

          @exported[name] = mail
        end
      end
    end
  end

  context "with users having email" do
    let(:user1) { create :gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
    let(:user2) { create :gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
    let(:user3) { create :gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
    let(:user4) { create :gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
    let!(:message) do
      create(
        :gws_memo_message, cur_site: site, cur_user: user1,
        in_to_members: [ user2.id ], in_cc_members: [ user3.id ], in_bcc_members: [ user4.id ]
      )
    end

    context "with unread message" do
      it do
        export_message.call
        expect(@exported.size).to eq 1

        basename = Fs.sanitize_filename("#{message.id}_#{message.display_subject}")
        expect(@exported.key?("#{I18n.t("gws/memo/folder.inbox")}/#{basename}.eml")).to be_truthy

        @exported["#{I18n.t("gws/memo/folder.inbox")}/#{basename}.eml"].tap do |mail|
          expect(mail.message_id.to_s).to eq "#{message.id}@#{canonical_domain}"
          expect(mail.sender).to be_nil
          expect(mail.date.to_s).to eq message.created.to_s
          expect(mail.subject).to eq message.subject
          expect(mail.mime_type).to eq "text/plain"
          expect(mail.multipart?).to be_falsey
          mail[:from].to_s.tap do |rfc2822_address|
            address = Mail::Address.new(rfc2822_address)
            expect(address.display_name).to eq user1.name
            expect(address.address).to eq user1.email
          end
          mail[:to].to_s.tap do |rfc2822_address|
            address = Mail::Address.new(rfc2822_address)
            expect(address.display_name).to eq user2.name
            expect(address.address).to eq user2.email
          end
          mail[:cc].to_s.tap do |rfc2822_address|
            address = Mail::Address.new(rfc2822_address)
            expect(address.display_name).to eq user3.name
            expect(address.address).to eq user3.email
          end
          expect(mail[:bcc]).to be_nil
          expect(mail[:reply_to]).to be_nil
          expect(mail[:in_reply_to]).to be_nil
          expect(mail[:references]).to be_nil
          expect(mail["X-Shirasagi-Status"].decoded).to eq "未読"
          expect(mail["X-Shirasagi-Version"].decoded).to eq SS.version
          expect(mail["X-Shirasagi-Exported"].decoded).to be_present
          expect(mail["X-Shirasagi-Tenant"].decoded).to eq SS::Crypto.crypt("#{site.id}:#{site.name}")
          body = mail.body.decoded
          body.force_encoding("UTF-8")
          expect(body).to include(message.text)
          expect(mail.parts).to be_blank
        end
      end
    end

    context "with read message" do
      before do
        Gws::Memo::Message.find(message.id).tap do |message|
          message.set_seen(user3)
          message.save!
        end

        message.reload
        expect(message.seen_at(user3)).to be_present
      end

      it do
        export_message.call
        expect(@exported.size).to eq 1

        basename = Fs.sanitize_filename("#{message.id}_#{message.display_subject}")
        expect(@exported.key?("#{I18n.t("gws/memo/folder.inbox")}/#{basename}.eml")).to be_truthy

        @exported["#{I18n.t("gws/memo/folder.inbox")}/#{basename}.eml"].tap do |mail|
          expect(mail["X-Shirasagi-Status"].decoded).to eq "既読"
        end
      end
    end

    context "with started message" do
      before do
        message.set_seen(user3)
        message.set_star(user3)
        message.save!
      end

      it do
        export_message.call
        expect(@exported.size).to eq 1

        basename = Fs.sanitize_filename("#{message.id}_#{message.display_subject}")
        expect(@exported.key?("#{I18n.t("gws/memo/folder.inbox")}/#{basename}.eml")).to be_truthy

        @exported["#{I18n.t("gws/memo/folder.inbox")}/#{basename}.eml"].tap do |mail|
          expect(mail["X-Shirasagi-Status"].decoded).to eq "既読, スター"
        end
      end
    end
  end

  context "with users having no email" do
    let(:user1) do
      create :gws_user, email: nil, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids
    end
    let(:user2) do
      create :gws_user, email: nil, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids
    end
    let(:user3) do
      create :gws_user, email: nil, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids
    end
    let(:user4) do
      create :gws_user, email: nil, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids
    end
    let!(:message) do
      create(
        :gws_memo_message, cur_site: site, cur_user: user1,
        in_to_members: [ user2.id ], in_cc_members: [ user3.id ], in_bcc_members: [ user4.id ]
      )
    end

    it do
      export_message.call
      expect(@exported.size).to eq 1

      basename = Fs.sanitize_filename("#{message.id}_#{message.display_subject}")
      expect(@exported.key?("#{I18n.t("gws/memo/folder.inbox")}/#{basename}.eml")).to be_truthy

      @exported["#{I18n.t("gws/memo/folder.inbox")}/#{basename}.eml"].tap do |mail|
        expect(mail.message_id.to_s).to eq "#{message.id}@#{canonical_domain}"
        expect(mail.sender).to be_nil
        expect(mail.date.to_s).to eq message.created.to_s
        expect(mail.subject).to eq message.subject
        expect(mail.mime_type).to eq "text/plain"
        expect(mail.multipart?).to be_falsey
        mail[:from].to_s.tap do |rfc2822_address|
          address = Mail::Address.new(rfc2822_address)
          expect(address.display_name).to eq user1.name

          local_part = Addressable::IDNA.to_ascii(user1.name)
          expect(address.address).to eq "#{local_part}@users.#{canonical_domain}"
        end
        mail[:to].to_s.tap do |rfc2822_address|
          address = Mail::Address.new(rfc2822_address)
          expect(address.display_name).to eq user2.name

          local_part = Addressable::IDNA.to_ascii(user2.name)
          expect(address.address).to eq "#{local_part}@users.#{canonical_domain}"
        end
        mail[:cc].to_s.tap do |rfc2822_address|
          address = Mail::Address.new(rfc2822_address)
          expect(address.display_name).to eq user3.name

          local_part = Addressable::IDNA.to_ascii(user3.name)
          expect(address.address).to eq "#{local_part}@users.#{canonical_domain}"
        end
        expect(mail[:bcc]).to be_nil
        expect(mail[:reply_to]).to be_nil
        expect(mail[:in_reply_to]).to be_nil
        expect(mail[:references]).to be_nil
        expect(mail["X-Shirasagi-Status"].decoded).to eq "未読"
        expect(mail["X-Shirasagi-Version"].decoded).to eq SS.version
        expect(mail["X-Shirasagi-Exported"].decoded).to be_present
        expect(mail["X-Shirasagi-Tenant"].decoded).to eq SS::Crypto.crypt("#{site.id}:#{site.name}")
        body = mail.body.decoded
        body.force_encoding("UTF-8")
        expect(body).to include(message.text)
        expect(mail.parts).to be_blank
      end
    end
  end

  context "with gws/shared_address/group" do
    let(:user1) { create :gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
    let(:user2) { create :gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
    let(:user3) { create :gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
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
    let!(:message) do
      create(
        :gws_memo_message, cur_site: site, cur_user: user3, in_to_members: [ "shared_group:#{shared_address_group1.id}" ]
      )
    end

    it do
      export_message.call
      expect(@exported.size).to eq 1

      basename = Fs.sanitize_filename("#{message.id}_#{message.display_subject}")
      expect(@exported.key?("#{I18n.t("gws/memo/folder.inbox_sent")}/#{basename}.eml")).to be_truthy

      @exported["#{I18n.t("gws/memo/folder.inbox_sent")}/#{basename}.eml"].tap do |mail|
        expect(mail.message_id.to_s).to eq "#{message.id}@#{canonical_domain}"
        expect(mail.sender).to be_nil
        expect(mail.date.to_s).to eq message.created.to_s
        expect(mail.subject).to eq message.subject
        expect(mail.mime_type).to eq "text/plain"
        expect(mail.multipart?).to be_falsey
        mail[:from].to_s.tap do |rfc2822_address|
          address = Mail::Address.new(rfc2822_address)
          expect(address.display_name).to eq user3.name
          expect(address.address).to eq user3.email
        end
        mail[:to].to_s.tap do |rfc2822_address|
          address = Mail::Address.new(rfc2822_address)
          expect(address.display_name).to eq shared_address_group1.name

          local_part = Addressable::IDNA.to_ascii(shared_address_group1.name)
          expect(address.address).to eq "#{local_part}@shared-groups.#{canonical_domain}"
        end
        expect(mail[:cc]).to be_nil
        expect(mail[:bcc]).to be_nil
        expect(mail[:reply_to]).to be_nil
        expect(mail[:in_reply_to]).to be_nil
        expect(mail[:references]).to be_nil
        expect(mail["X-Shirasagi-Status"].decoded).to eq "未読"
        expect(mail["X-Shirasagi-Version"].decoded).to eq SS.version
        expect(mail["X-Shirasagi-Exported"].decoded).to be_present
        expect(mail["X-Shirasagi-Tenant"].decoded).to eq SS::Crypto.crypt("#{site.id}:#{site.name}")
        body = mail.body.decoded
        body.force_encoding("UTF-8")
        expect(body).to include(message.text)
        expect(mail.parts).to be_blank
      end
    end
  end

  context "with attachments" do
    let(:user1) { create :gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
    let(:user2) { create :gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
    let(:user3) { create :gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
    let(:file1) do
      tmp_ss_file cur_user: user1, contents: "#{Rails.root}/spec/fixtures/ss/logo.png", model: "ss/temp_file"
    end
    let(:file2) do
      tmp_ss_file cur_user: user1, contents: "#{Rails.root}/spec/fixtures/ss/shirasagi.pdf", model: "ss/temp_file"
    end
    let!(:message) do
      create(
        :gws_memo_message, cur_site: site, cur_user: user1, in_to_members: [ user2.id, user3.id ],
        file_ids: [ file1.id, file2.id ]
      )
    end

    it do
      Gws::Memo::Message.find(message.id).tap do |message|
        expect(message.file_ids).to have(2).items
      end

      export_message.call
      expect(@exported.size).to eq 1

      basename = Fs.sanitize_filename("#{message.id}_#{message.display_subject}")
      expect(@exported.key?("#{I18n.t("gws/memo/folder.inbox")}/#{basename}.eml")).to be_truthy

      @exported["#{I18n.t("gws/memo/folder.inbox")}/#{basename}.eml"].tap do |mail|
        expect(mail.message_id.to_s).to eq "#{message.id}@#{canonical_domain}"
        expect(mail.sender).to be_nil
        expect(mail.date.to_s).to eq message.created.to_s
        expect(mail.subject).to eq message.subject
        expect(mail.mime_type).to eq "multipart/mixed"
        expect(mail.multipart?).to be_truthy
        mail[:from].to_s.tap do |rfc2822_address|
          address = Mail::Address.new(rfc2822_address)
          expect(address.display_name).to eq user1.name
          expect(address.address).to eq user1.email
        end
        mail[:to].to_s.tap do |rfc2822_address_list|
          address_list = Mail::AddressList.new(rfc2822_address_list)
          expect(address_list.addresses.count).to eq 2
          expect(address_list.addresses.map(&:display_name)).to include(user2.name, user3.name)
          expect(address_list.addresses.map(&:address)).to include(user2.email, user3.email)
        end
        expect(mail[:cc]).to be_nil
        expect(mail[:bcc]).to be_nil
        expect(mail[:reply_to]).to be_nil
        expect(mail[:in_reply_to]).to be_nil
        expect(mail[:references]).to be_nil
        expect(mail["X-Shirasagi-Status"].decoded).to eq "未読"
        expect(mail["X-Shirasagi-Version"].decoded).to eq SS.version
        expect(mail["X-Shirasagi-Exported"].decoded).to be_present
        expect(mail["X-Shirasagi-Tenant"].decoded).to eq SS::Crypto.crypt("#{site.id}:#{site.name}")
        body_part = mail.text_part
        expect(body_part.mime_type).to eq "text/plain"
        body = body_part.decoded
        body.force_encoding("UTF-8")
        expect(body).to include(message.text)
        expect(mail.parts).to be_truthy
        expect(mail.parts.size).to eq 3
        mail.parts.each do |part|
          next if part == body_part

          case part.mime_type
          when "image/png"
            expect(Fs.compare_stream_head(StringIO.new(part.body.decoded), file1.to_io)).to be_truthy
          when "application/pdf"
            expect(Fs.compare_stream_head(StringIO.new(part.body.decoded), file2.to_io)).to be_truthy
          end
        end
      end
    end
  end

  context "with webmail/address_group" do
    let(:user1) { create :gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
    let(:user2) { create :gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
    let(:user3) { create :gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
    let!(:address_group1) { create :webmail_address_group, cur_user: user1 }
    let!(:address1) do
      create :webmail_address, cur_user: user1, address_group: address_group1, member: user2, name: user2.name
    end
    let!(:address2) do
      create :webmail_address, cur_user: user1, address_group: address_group1, member: user3, name: user3.name
    end
    let!(:message) do
      create(
        :gws_memo_message, cur_site: site, cur_user: user1, in_to_members: [ "webmail_group:#{address_group1.id}" ]
      )
    end

    it do
      export_message.call
      expect(@exported.size).to eq 1

      basename = Fs.sanitize_filename("#{message.id}_#{message.display_subject}")
      expect(@exported.key?("#{I18n.t("gws/memo/folder.inbox")}/#{basename}.eml")).to be_truthy

      @exported["#{I18n.t("gws/memo/folder.inbox")}/#{basename}.eml"].tap do |mail|
        expect(mail.message_id.to_s).to eq "#{message.id}@#{canonical_domain}"
        expect(mail.sender).to be_nil
        expect(mail.date.to_s).to eq message.created.to_s
        expect(mail.subject).to eq message.subject
        expect(mail.mime_type).to eq "text/plain"
        expect(mail.multipart?).to be_falsey
        mail[:from].to_s.tap do |rfc2822_address|
          address = Mail::Address.new(rfc2822_address)
          expect(address.display_name).to eq user1.name
          expect(address.address).to eq user1.email
        end
        mail[:to].to_s.tap do |rfc2822_address|
          address = Mail::Address.new(rfc2822_address)
          expect(address.display_name).to eq address_group1.name

          local_part = Addressable::IDNA.to_ascii(address_group1.name)
          expect(address.address).to eq "#{local_part}@personal-groups.#{canonical_domain}"
        end
        expect(mail[:cc]).to be_nil
        expect(mail[:bcc]).to be_nil
        expect(mail[:reply_to]).to be_nil
        expect(mail[:in_reply_to]).to be_nil
        expect(mail[:references]).to be_nil
        expect(mail["X-Shirasagi-Status"].decoded).to eq "未読"
        expect(mail["X-Shirasagi-Version"].decoded).to eq SS.version
        expect(mail["X-Shirasagi-Exported"].decoded).to be_present
        expect(mail["X-Shirasagi-Tenant"].decoded).to eq SS::Crypto.crypt("#{site.id}:#{site.name}")
        body = mail.body.decoded
        body.force_encoding("UTF-8")
        expect(body).to include(message.text)
        expect(mail.parts).to be_blank
      end
    end
  end

  context "with list message" do
    let(:user1) { create :gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
    let(:user2) { create :gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
    let(:user3) { create :gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
    let!(:list) { create :gws_memo_list, cur_site: site, member_ids: [ user2.id, user3.id ] }
    let!(:message) do
      create(
        :gws_memo_list_message, cur_user: user1, cur_site: site,
        list: list, from_member_name: list.sender_name, member_ids: list.overall_members.map(&:id),
        in_validate_presence_member: true, in_append_signature: true, in_skip_validates_sender_quota: true,
        state: "public"
      )
    end

    it do
      export_message.call
      expect(@exported.size).to eq 1

      basename = Fs.sanitize_filename("#{message.id}_#{message.display_subject}")
      expect(@exported.key?("#{I18n.t("gws/memo/folder.inbox")}/#{basename}.eml")).to be_truthy

      @exported["#{I18n.t("gws/memo/folder.inbox")}/#{basename}.eml"].tap do |mail|
        expect(mail.message_id.to_s).to eq "#{message.id}@#{canonical_domain}"
        expect(mail.sender).to be_nil
        expect(mail.date.to_s).to eq message.created.to_s
        expect(mail.subject).to eq message.subject
        expect(mail.mime_type).to eq "text/plain"
        expect(mail.multipart?).to be_falsey
        mail[:from].to_s.tap do |rfc2822_address|
          address = Mail::Address.new(rfc2822_address)
          expect(address.display_name).to eq list.sender_name

          local_part = Base64.strict_encode64(list.sender_name)
          expect(address.address).to eq "#{local_part}@lists.#{canonical_domain}"
        end
        mail[:to].to_s.tap do |rfc2822_address|
          address = Mail::Address.new(rfc2822_address)
          expect(address.display_name).to eq list.name

          local_part = Addressable::IDNA.to_ascii(list.name)
          expect(address.address).to eq "#{local_part}@lists.#{canonical_domain}"
        end
        expect(mail[:cc]).to be_nil
        expect(mail[:bcc]).to be_nil
        expect(mail[:reply_to]).to be_nil
        expect(mail[:in_reply_to]).to be_nil
        expect(mail[:references]).to be_nil
        expect(mail["X-Shirasagi-Status"].decoded).to eq "未読"
        expect(mail["X-Shirasagi-Version"].decoded).to eq SS.version
        expect(mail["X-Shirasagi-Exported"].decoded).to be_present
        expect(mail["X-Shirasagi-Tenant"].decoded).to eq SS::Crypto.crypt("#{site.id}:#{site.name}")
        body = mail.body.decoded
        body.force_encoding("UTF-8")
        expect(body).to include(message.text)
        expect(mail.parts).to be_blank
      end
    end
  end
end
