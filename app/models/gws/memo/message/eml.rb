class Gws::Memo::Message
  module Eml
    module_function

    def read(user, io, site:)
      reader = Gws::Memo::Message::EmlReader.new(site: site, user: user, io: io)
      reader.call
    end

    def write(user, message, io, site: nil)
      writer = Gws::Memo::Message::EmlWriter.new(site: site || message.site, user: user, message: message, io: io)
      writer.call
    end

    def address_type(address)
      if address.include?("@users.")
        :users
      elsif address.include?("@shared-groups.")
        :shared_groups
      elsif address.include?("@personal-groups.")
        :personal_groups
      elsif address.include?("@lists.")
        :lists
      else
        :others
      end
    end

    def decode_local_part(address)
      local_part, = address.split("@", 2)

      decoded = Base64.strict_decode64(local_part) rescue nil
      if decoded
        decoded = decoded.encode("UTF-8") rescue nil
      end
      if decoded
        local_part = decoded
      end

      local_part
    end

    def multi_part?(mail_header)
      return false unless mail_header

      content_type = mail_header.header[:content_type]
      return false unless content_type

      mime_type = content_type.string
      return false unless mime_type

      # multipart's mime type can be "multipart/mixed" or "multipart/alternative"
      mime_type = mime_type.downcase
      return false unless mime_type.start_with?("multipart/")

      boundary = content_type.parameters["boundary"]
      return false if boundary.blank?

      true
    end

    def text_part?(mail_header)
      return false unless mail_header

      content_type = mail_header.header[:content_type]
      return false unless content_type

      mime_type = content_type.string
      return false unless mime_type

      mime_type = mime_type.downcase
      mime_type.start_with?("text/")
    end
  end

  class AddressListResolver
    include ActiveModel::Model

    attr_accessor :site, :user, :lists
    attr_reader :user_criterias, :shared_group_names, :personal_group_names, :list_names

    private_class_method :new

    def initialize(*args)
      super

      @user_criterias = []
      @shared_group_names = []
      @personal_group_names = []
      @list_names = []
    end

    def self.parse(site, user, address_list, lists: true)
      struct = new(lists: lists, site: site, user: user)

      address_list = Mail::AddressList.new(address_list)
      address_list.addresses.each do |address|
        email = address.address
        case Eml.address_type(email)
        when :users
          name = Eml.decode_local_part(email)
          if name.present?
            struct.user_criterias << { name: name }
          end
        when :shared_groups
          name = Eml.decode_local_part(email)
          if name.present?
            struct.shared_group_names << name
          end
        when :personal_groups
          name = Eml.decode_local_part(email)
          if name.present?
            struct.personal_group_names << name
          end
        when :lists
          if lists
            name = Eml.decode_local_part(email)
            if name.present?
              struct.list_names << name
            end
          end
        else
          struct.user_criterias << { email: email }
        end
      end

      struct
    end

    def user_ids
      return if user_criterias.blank?

      users = Gws::User.all.site(site).where("$and" => [{ "$or" => user_criterias }])
      return users.pluck(:id) if users.count == user_criterias.length

      # name の重複がある。重複したユーザーは除外する。
      users = users.to_a.group_by { |user| user.name }
      users = users.map { |_name, users| users }.select { |users| users.length == 1 }
      users.map! { |users| users.first }
      return if users.blank?

      users.map(&:id)
    end

    def shared_group_ids
      return if shared_group_names.blank?

      group_ids = Gws::SharedAddress::Group.all.site(site).in(name: shared_group_names).pluck(:id)
      return if group_ids.blank?

      group_ids
    end

    def personal_group_ids
      return if personal_group_names.blank?

      group_ids = Webmail::AddressGroup.all.where(user_id: user.id).in(name: personal_group_names).pluck(:id)
      return if group_ids.blank?

      group_ids
    end

    def list
      return if !lists || list_names.blank?

      lists = Gws::Memo::List.all.site(site).in(name: list_names)
      return  if lists.count != 1

      lists.order_by(name: 1, id: 1).first
    end
  end

  class RawReader
    private_class_method :new

    class << self
      def wrap(reader)
        new(reader)
      end

      def header_line?(line)
        line.present? && (line.include?(":") || [ " ", "\t" ].include?(line[0]))
      end
    end

    def initialize(reader)
      @reader = reader
    end

    def headers
      return @headers if @headers

      @headers = []

      @reader.each_line do |line|
        if !self.class.header_line?(line)
          @pending_line = line if line.present?
          break
        end

        line.chomp!
        @headers << line
      end

      @headers
    end

    def remains
      Enumerator.new do |y|
        y << @pending_line if @pending_line.present?
        @reader.each_line do |line|
          y << line
        end
      end
    end

    def each_part(boundary)
      if !@pending_line || !@pending_line.start_with?("--#{boundary}")
        @reader.each_line do |line|
          break if line.start_with?("--#{boundary}")
        end
      end

      loop do
        part_headers = []
        pending_line = nil
        @reader.each_line do |line|
          unless self.class.header_line?(line)
            pending_line = line if line.present?
            break
          end

          part_headers << line
        end
        break if part_headers.blank?

        part_header = Mail.new(part_headers.join)

        body_enumerable = Enumerator.new do |y|
          y << pending_line if pending_line

          @reader.each_line do |line|
            break if line.start_with?("--#{boundary}")
            y << line
          end
        end

        yield part_header, body_enumerable
      end
    end
  end

  class EmlReader
    include ActiveModel::Model

    attr_accessor :site, :user, :io, :now
    attr_reader :message, :raw_reader

    HEADER_READERS = %i[
      read_tenant read_version read_exported
      read_subject read_date read_message_id read_from read_to read_cc read_status
    ].freeze

    def initialize(*args)
      super

      self.site ||= message.site
      self.now ||= Time.zone.now

      @raw_reader = RawReader.wrap(io)
    end

    def call
      if list_message?
        @message = Gws::Memo::ListMessage.new
      else
        @message = Gws::Memo::Message.new
      end
      message.cur_site = site
      message.member_ids = [ user.id ]

      read_headers
      read_body_and_attachments

      message
    end

    private

    def mail_header
      @mail_header ||= Mail.new(raw_reader.headers.join("\r\n"))
    end

    def list_message?
      address_list = Mail::AddressList.new(mail_header[:from].to_s)
      address_list.addresses.any? { |address| address.address.include?("@lists.") }
    end

    def read_headers
      HEADER_READERS.each do |handler|
        send(handler)
      end
    end

    def read_tenant
      tenant = mail_header.header["X-Shirasagi-Tenant"]
      return unless tenant

      @tenant_matched = tenant.to_s == SS::Crypt.crypt("#{site.id}:#{site.name}")
    end

    def read_version
      version = mail_header.header["X-Shirasagi-Version"]
      return unless version

      @version_matched = version.to_s == SS.version
    end

    def read_exported
      # nothing to do
    end

    def read_subject
      message.subject = mail_header.subject
    end

    def read_date
      message.send_date = mail_header.date.try(:in_time_zone)
    end

    def read_message_id
      # nothing to do
    end

    def read_from
      if @tenant_matched
        address_list = Mail::AddressList.new(mail_header[:from].to_s)
        address_list.addresses.any? do |address|
          case address_type = Eml.address_type(address.address)
          when :users, :others
            criteria = Gws::User.all.site(site)
            if address_type == :users
              name = Eml.decode_local_part(address.address)
              users = criteria.where(name: name)
            else
              users = criteria.where(email: address.address)
            end
            if users.count == 1
              from = users.first
              message.cur_user = from
              message.user_id = from.id
              message.user_uid = from.uid
              message.user_name = from.name
              message.from_member_name = from.long_name
              true
            end
          when :shared_groups, :personal_groups, :lists
            message.cur_user = nil
            message.from_member_name = address.display_name.presence || Eml.decode_local_part(address.address)
            true
          end
        end
      else
        message.user_id = nil
        message.from_member_name = mail_header[:from].to_s
      end
    end

    def read_to
      unless @tenant_matched
        message.to_member_name = mail_header[:to].to_s
        return
      end

      resolved = Gws::Memo::Message::AddressListResolver.parse(site, user, mail_header[:to].to_s, lists: true)
      resolved.user_ids.try do |user_id|
        message.to_member_ids = user_id if user_id.present?
      end
      resolved.shared_group_ids.try do |group_ids|
        message.to_shared_address_group_ids = group_ids if group_ids.present?
      end
      resolved.personal_group_ids.try do |group_ids|
        message.to_webmail_address_group_ids = group_ids if group_ids.present?
      end
      resolved.list.try do |list|
        message.list = list
      end
    end

    def read_cc
      unless @tenant_matched
        # message.cc_member_name = mail_header[:to].to_s
        return
      end

      resolved = Gws::Memo::Message::AddressListResolver.parse(site, user, mail_header[:cc].to_s, lists: false)
      resolved.user_ids.try do |user_id|
        message.cc_member_ids = user_id if user_id.present?
      end
      resolved.shared_group_ids.try do |group_ids|
        message.cc_shared_address_group_ids = group_ids if group_ids.present?
      end
      resolved.personal_group_ids.try do |group_ids|
        message.cc_webmail_address_group_ids = group_ids if group_ids.present?
      end
    end

    def read_status
      return unless @tenant_matched

      status_list = mail_header["X-Shirasagi-Status"]
      return if status_list.blank?

      statuses = status_list.to_s.split(",").map(&:strip)
      if statuses.include?("スター")
        message.set_star(user)
      end
    end

    def read_body_and_attachments
      if !Eml.multi_part?(mail_header)
        read_body mail_header, raw_reader.remains
        return
      end

      content_type = mail_header.header[:content_type]
      boundary = content_type.parameters["boundary"]

      index = 0
      raw_reader.each_part(boundary) do |part_header, part_body_enum|
        if index == 0 && Eml.text_part?(part_header)
          read_body part_header, part_body_enum
          index += 1
          next
        end

        read_part part_header, part_body_enum
        index += 1
      end
    end

    def read_body(part_header, part_body_enum)
      message.format = "text"
      message.html = nil
      message.text = nil

      body = part_body_enum.to_a
      return if body.blank?

      body.map!(&:chomp)
      body.select!(&:present?)
      return if body.blank?

      content_transfer_encoding = part_header.header[:content_transfer_encoding]
      if content_transfer_encoding && content_transfer_encoding.encoding.present?
        case content_transfer_encoding.encoding.downcase
        when "base64"
          body = Mail::Encodings::Base64.decode(body.join("\r\n"))
        when "quoted-printable"
          body = Mail::Encodings::QuotedPrintable.decode(body.join("\r\n"))
        else # 7bit
          body = body.join("\r\n")
        end
      else
        body = body.join("\r\n")
      end

      body = NKF.nkf("-Ww", body)

      content_type = part_header.header[:content_type]
      if content_type && content_type.string == "text/html"
        message.format = "html"
        message.html = body
      else
        message.format = "text"
        message.text = body
      end
    end

    def read_part(part_header, part_body_enum)
      content_type = part_header.header[:content_type]
      filename = content_type.parameters["filename"] if content_type && content_type.parameters
      if filename.present?
        ext = ::File.extname(filename)
        ext = ext[1..-1] if ext && ext.start_with?(".")
      end
      if ext.present?
        content_type = SS::MimeType.find(ext)
      else
        content_type = SS::MimeType::DEFAULT_MIME_TYPE
      end
      filename ||= "no_name"
      attributes = {
        model: "gws/memo/message", name: filename, filename: filename, content_type: content_type
      }
      attributes[:cur_user] = message.cur_user if message.cur_user
      file = SS::File.create_empty!(attributes) do |new_file|
        ::File.open(new_file.path, "wb") do |writer|
          part_body_enum.each do |line|
            data = Base64.strict_decode64(line.strip)
            writer.write data
          end
        end
      end

      message.file_ids = Array(message.file_ids) + [ file.id ]
    end
  end

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

        SS::File.each_file(message.file_ids) do |file|
          header = {
            "Content-Type" => "#{file.content_type}; filename=#{file.filename.toutf8}",
            "Content-Transfer-Encoding" => "base64",
            "Content-Disposition" => "attachment; filename=#{file.filename.toutf8}; charset=UTF-8"
          }

          file.to_io do |io|
            y << [ header, io ]
          end
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
      buff = ""

      io.write "Content-Type: multipart/mixed;\r\n"
      io.write " boundary=\"#{boundary}\"\r\n"
      io.write "\r\n"
      enumerator.each do |header, body|
        io.write "--#{boundary}\r\n"
        header.each do |key, value|
          io.write "#{key}: #{value}\r\n"
        end
        io.write "\r\n"
        # io.write body
        while body.read(45, buff)
          io.write Base64.strict_encode64(buff)
          io.write "\r\n"
        end

        io.write "\r\n"
      end
      io.write "--#{boundary}--\r\n"
    end
  end
end
