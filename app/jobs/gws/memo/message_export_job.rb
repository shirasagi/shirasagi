class Gws::Memo::MessageExportJob < Gws::ApplicationJob
  include Gws::Memo::Helper

  def perform(*args)
    opts = args.extract_options!
    @datetime = Time.zone.now
    @message_ids = args[0]
    @root_url = opts[:root_url].to_s
    @output_zip = SS::ZipCreator.new("gws-memo-messages.zip", user, site: site)
    @export_filter = opts[:export_filter].to_s.presence || "selected"
    @exported_items = 0

    export_gws_memo_messages
    @output_zip.close

    if @exported_items == 0
      create_notify_message(failed: true, failed_message: I18n.t("gws/memo/message.export_failed.empty_messages"))
      return
    end

    create_notify_message
    Rails.logger.info("#{@exported_items.to_s(:delimied)} 件のメッセージをエクスポートしました。")
  ensure
    @output_zip.close if @output_zip
  end

  private

  def export_gws_memo_messages
    each_message_with_rescue do |item|
      basename = ::Fs.sanitize_filename("#{item.id}_#{item.display_subject}")
      folder_name = item_folder_name(item)
      next if folder_name.blank?

      folder_name = folder_name.split("/").map { |path| ::Fs.sanitize_filename(path) }.join("/")
      basename = "#{folder_name}/#{basename}"

      @output_zip.create_entry("#{basename}.eml") do |f|
        write_eml(f, item)
      end
      @exported_items += 1
    end
  end

  def each_message_with_rescue
    criteria = Gws::Memo::Message.unscoped.site(site).where("user_settings.user_id" => user.id)
    if @export_filter == "all"
      all_ids = criteria.pluck(:id).map(&:to_s) + extract_sent_and_draft_ids
    else
      extract_sent_and_draft_ids
      all_ids = @message_ids
    end

    all_ids.each_slice(100) do |ids|
      Gws::Memo::Message.in(id: ids).to_a.each do |item|
        item = Gws::Memo::ListMessage.find(item.id) if item.attributes[:list_id].present?

        Rails.logger.tagged("#{item.id}_#{item.display_subject}") do
          yield item
        rescue => e
          Rails.logger.warn { "#{item.name}(#{item.id}) をエクスポート中に例外が発生しました。" }
          Rails.logger.warn { "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}" }
        end
      end
    end
  end

  def extract_sent_and_draft_ids
    folders = Gws::Memo::Folder.static_items(user, site) + Gws::Memo::Folder.user(user).site(site)

    sent_folder = folders.find { |folder| folder.folder_path == "INBOX.Sent" }
    draft_folder = folders.find { |folder| folder.folder_path == "INBOX.Draft" }

    @sent_ids = Gws::Memo::Message.folder(sent_folder, user).pluck(:id).map(&:to_s)
    @draft_ids = Gws::Memo::Message.folder(draft_folder, user).pluck(:id).map(&:to_s)
    @sent_ids + @draft_ids
  end

  def item_folder_name(item)
    path = item.path(user)
    if path.blank? || item.state == "closed"
      if @sent_ids.include?(item.id.to_s)
        path = "INBOX.Sent"
      elsif @draft_ids.include?(item.id.to_s)
        path = "INBOX.Draft"
      end
    end
    return if path.blank?

    if !path.numeric?
      return I18n.t("gws/memo/folder.#{path.downcase.tr(".", "_")}", default: path)
    end

    folder = Gws::Memo::Folder.site(site).user(user).where(id: path.to_i).first
    return if folder.blank?

    folder.name
  end

  def create_notify_message(opts = {})
    item = SS::Notification.new
    item.cur_group = site
    item.cur_user = user
    item.member_ids = [user.id]
    item.format = "text"
    item.send_date = @datetime

    if opts[:failed]
      item.subject = I18n.t("gws/memo/message.export_failed.subject")
      item.text = opts[:failed_message].presence || I18n.t("gws/memo/message.export_failed.notify_message")
    else
      item.subject = I18n.t("gws/memo/message.export.subject")
      link = ::File.join(@root_url, @output_zip.url(name: "gws-memo-messages-#{@datetime.strftime('%Y%m%d%H%M%S')}.zip"))
      item.text = I18n.t("gws/memo/message.export.notify_message", link: link)
    end

    item.save!
  end

  def write_eml(io, item)
    io.puts encoded_eml_field("Subject", sanitize_content(item.subject))
    io.puts encoded_eml_field("Date", item.created.in_time_zone.rfc822)
    io.puts encoded_eml_field("Message-ID", gen_message_id(item))
    if item.try(:from)
      io.puts encoded_eml_field("From", user_name_email(item.from))
    elsif list = item.try(:list)
      name = list.sender_name.presence || list.name
      io.puts encoded_eml_field("From", Gws::Memo.rfc2822_mailbox(site: site, name: name, sub: "lists"))
    elsif item.from_member_name.present?
      name = item.from_member_name
      io.puts encoded_eml_field("From", Gws::Memo.rfc2822_mailbox(site: site, name: name, sub: "others"))
    end
    build_to_members_name_email(item).try { |value| io.puts encoded_eml_field("To", value) }
    build_cc_members_name_email(item).try { |value| io.puts encoded_eml_field("Cc", value) }
    build_status(item).try { |value| io.puts encoded_eml_field("X-Shirasagi-Status", value) }
    io.puts encoded_eml_field("X-Shirasagi-Version", SS.version)
    io.puts encoded_eml_field("X-Shirasagi-Exported", @datetime.rfc822)
    io.puts encoded_eml_field("X-Shirasagi-Tenant", SS::Crypt.crypt("#{site.id}:#{site.name}"))
    if item.files.blank?
      write_body_to_eml(io, item)
      return
    end

    enumerator = Enumerator.new do |y|
      y << serialize_body(item)

      SS.each_file(item.file_ids) do |file|
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

  def build_status(item)
    statuses = []

    if item.seen_at(user).present?
      statuses << "既読"
    else
      statuses << "未読"
    end

    if item.star?(user)
      statuses << "スター"
    end

    statuses.presence
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
    io.puts "Content-Type: multipart/mixed;"
    io.puts " boundary=\"#{boundary}\""
    io.puts ""
    io.puts ""
    io.puts "--#{boundary}"
    enumerator.each do |header, body|
      header.each do |key, value|
        io.puts "#{key}: #{value}"
      end
      io.puts ""
      io.puts body
      io.puts ""
      io.puts "--#{boundary}--"
    end
  end
end
