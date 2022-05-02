class Gws::Memo::Message
  class EmlWriter
    include ActiveModel::Model
    include Gws::Memo::Helper

    attr_accessor :site, :user, :message, :io, :now

    HEADER_WRITERS = %i[
      write_subject write_date write_message_id write_from write_to write_cc write_status write_version
      write_exported write_tenant
    ].freeze

    def initialize(*args)
      super

      self.site ||= message.site
      self.now ||= Time.zone.now
    end

    def call
      write_headers

      if message.files.blank?
        write_body_to_eml(io, message)
        return
      end

      enumerator = Enumerator.new do |y|
        y << serialize_body(message)

        SS.each_file(message.file_ids) do |file|
          header = {
            "Content-Type" => "#{file.content_type}; filename=#{file.filename.toutf8}",
            "Content-Transfer-Encoding" => "base64",
            "Content-Disposition" => "attachment; filename=#{file.filename.toutf8}; charset=UTF-8"
          }

          y << [ header, Base64.strict_encode64(::File.binread(file.path)) ]
        end
      end

      serialize_multi_part io, enumerator
    end

    private

    def write_headers
      HEADER_WRITERS.each do |handler|
        send(handler)
      end
    end

    def write_subject
      io.write encoded_eml_field("Subject", sanitize_content(message.subject))
    end

    def write_date
      date = message.created || now
      io.write encoded_eml_field("Date", date.in_time_zone.rfc822)
    end

    def write_message_id
      io.write encoded_eml_field("Message-ID", gen_message_id(message))
    end

    def write_from
      if message.try(:from)
        io.write encoded_eml_field("From", user_name_email(message.from))
      elsif list = message.try(:list)
        name = list.sender_name.presence || list.name
        io.write encoded_eml_field("From", Gws::Memo.rfc2822_mailbox(site: site, name: name, sub: "lists"))
      elsif message.from_member_name.present?
        name = message.from_member_name
        io.write encoded_eml_field("From", Gws::Memo.rfc2822_mailbox(site: site, name: name, sub: "others"))
      end
    end

    def write_to
      value = build_to_members_name_email(message)
      return if value.blank?

      io.write encoded_eml_field("To", value)
    end

    def write_cc
      value = build_cc_members_name_email(message)
      return if value.blank?

      io.write encoded_eml_field("Cc", value)
    end

    def write_status
      statuses = []
      if message.seen_at(user).present?
        statuses << "既読"
      else
        statuses << "未読"
      end

      if message.star?(user)
        statuses << "スター"
      end

      return if statuses.blank?

      io.write encoded_eml_field("X-Shirasagi-Status", statuses)
    end

    def write_version
      io.write encoded_eml_field("X-Shirasagi-Version", SS.version)
    end

    def write_exported
      io.write encoded_eml_field("X-Shirasagi-Exported", now.rfc822)
    end

    def write_tenant
      io.write encoded_eml_field("X-Shirasagi-Tenant", SS::Crypt.crypt("#{site.id}:#{site.name}"))
    end

    def encoded_eml_field(field_name, value, charset: "utf-8")
      Mail::Field.new(field_name, value, charset).encoded
    end

    def build_to_members_name_email(item)
      if item.to_members.present?
        to_members_name_email = item.to_members.map { |u| user_name_email(u) }
      else
        to_members_name_email = []
      end

      list = item.try(:list)
      if list.present?
        to_members_name_email << Gws::Memo.rfc2822_mailbox(site: site, name: list.name, sub: "lists")
      end

      to_members_name_email = [] if to_members_name_email.nil?
      if item.to_shared_address_group_ids.present?
        item.to_shared_address_group_ids.each do |u|
          to_members_name_email << shared_address_group_name(u)
        end
      end

      if item.to_webmail_address_group_ids
        item.to_webmail_address_group_ids.each do |u|
          to_members_name_email << webmail_address_group_name(u)
        end
      end

      to_members_name_email.presence
    end

    def build_to_member_ids(item)
      return if item.to_members.blank?
      item.to_members.map(&:id).presence
    end

    def build_cc_member_ids(item)
      return if item.cc_members.blank?
      item.cc_members.map(&:id).presence
    end

    def build_cc_members_name_email(item)
      if item.cc_members.present?
        cc_members_name_email = item.cc_members.map { |u| user_name_email(u) }
      end

      cc_members_name_email ||= []
      if item.cc_shared_address_group_ids
        item.cc_shared_address_group_ids.map do |u|
          cc_members_name_email << shared_address_group_name(u)
        end
      end

      if item.cc_webmail_address_group_ids
        item.cc_webmail_address_group_ids.map do |u|
          cc_members_name_email << webmail_address_group_name(u)
        end
      end

      cc_members_name_email.presence
    end

    def shared_address_group_name(id)
      group = Gws::SharedAddress::Group.find(id) rescue nil
      Gws::Memo.rfc2822_mailbox(site: site, name: group.try(:name), sub: "shared-groups")
    end

    def webmail_address_group_name(id)
      group = Webmail::AddressGroup.find(id) rescue nil
      Gws::Memo.rfc2822_mailbox(site: site, name: group.try(:name), sub: "personal-groups")
    end

    def serialize_multi_part(io, enumerator)
      boundary = "--==_mimepart_#{SecureRandom.hex(16)}"
      io.write "Content-Type: multipart/mixed;\r\n"
      io.write " boundary=\"#{boundary}\"\r\n"
      io.write "\r\n"
      io.write "\r\n"
      io.write "--#{boundary}\r\n"
      enumerator.each do |header, body|
        header.each do |key, value|
          io.write "#{key}: #{value}\r\n"
        end
        io.write "\r\n"
        io.write body
        io.write "\r\n"
        io.write "\r\n"
        io.write "--#{boundary}--\r\n"
      end
    end
  end

  class Eml
    def self.write(user, message, io, site: nil)
      writer = EmlWriter.new(site: site || message.site, user: user, message: message, io: io)
      writer.call
    end
  end
end
