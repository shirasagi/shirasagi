class Gws::Memo::MessageExportJob < Gws::ApplicationJob
  include SS::ExportHelper

  def perform(*args)
    opts = args.extract_options!
    @datetime = Time.zone.now
    @message_ids = args
    @root_url = opts[:root_url].to_s
    @output_zip = SS::ZipCreator.new("gws-memo-messages.zip", user, site: site)
    @output_format = opts[:format].to_s.presence || "json"
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
      data = item.attributes

      if item.user
        data['user'] = user_attributes(item.user)
      end
      if item.members.present?
        data['members'] = item.members.map { |u| user_attributes(u) }
      end
      if item.to_members.present?
        data['to_members'] = item.to_members.map { |u| user_attributes(u) }
        data['to_members_name_email'] = item.to_members.map { |u| user_name_email(u) }
      end
      if item.cc_members.present?
        data['cc_members'] = item.cc_members.map { |u| user_attributes(u) }
        data['cc_members_name_email'] = item.cc_members.map { |u| user_name_email(u) }
      end
      if item.bcc_members.present?
        data['bcc_members'] = item.bcc_members.select{ |u| u.id == user.id }.map { |u| user_attributes(u) }
      end
      if item.files.present?
        data['files'] = item.files.map { |file| file_attributes(file) }
      end
      if item.from
        data['from_name_email'] = user_name_email(item.from)
      end
      data['export_info'] = { 'version' => SS.version, 'exported' => @datetime }

      basename = sanitize_filename("#{item.id}_#{item.display_subject}")
      folder_name = item_folder_name(item)
      if folder_name.present?
        folder_name = folder_name.split("/").map { |path| sanitize_filename(path) }.join("/")
        basename = "#{folder_name}/#{basename}"
      end
      if @output_format == "eml"
        write_eml(basename, data)
      else
        write_json(basename, data.to_json)
      end

      @exported_items += 1
    end
  end

  def each_message_with_rescue
    criteria = Gws::Memo::Message.unscoped.site(site).where("user_settings.user_id" => user.id)
    if @export_filter == "all"
      all_ids = criteria.pluck(:id).map(&:to_s)
    else
      all_ids = @message_ids
    end

    all_ids.each_slice(100) do |ids|
      criteria.in(id: ids).to_a.each do |item|
        begin
          yield item
        rescue => e
          Rails.logger.warn("#{item.name}(#{item.id}) をエクスポート中に例外が発生しました。")
          Rails.logger.warn("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
        end
      end
    end
  end

  def item_folder_name(item)
    path = item.path(user)
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

  def write_json(name, data)
    @output_zip.create_entry("#{name}.json") do |f|
      f.write(data)
    end
  end

  def write_eml(name, data)
    @output_zip.create_entry("#{name}.eml") do |f|
      f.puts Mail::Field.new("Date", data["created"].in_time_zone.rfc822, "utf-8").encoded
      f.puts Mail::Field.new("Message-ID", gen_message_id(data), "utf-8").encoded
      f.puts Mail::Field.new("Subject", data["subject"], "utf-8").encoded
      f.puts Mail::Field.new("From", data['from_name_email'], "utf-8").encoded
      f.puts Mail::Field.new("To", data['to_members_name_email'], "utf-8").encoded
      f.puts Mail::Field.new("Cc", data['cc_members_name_email'], "utf-8").encoded if data['cc_members_name_email'].present?
      user_settings = data["user_settings"]
      s_status = []
      if user_settings.present?
        if user_settings.any? { |user_setting| user_setting["user_id"] == user.id && user_setting["seen_at"].present? }
          s_status << "既読"
        else
          s_status << "未読"
        end
      end
      if data["star"].any? { |key, value| key == user.id.to_s }
        s_status << "スター"
      end
      if s_status.present?
        f.puts Mail::Field.new("X-Shirasagi-Status", s_status, "utf-8").encoded
      end
      f.puts Mail::Field.new("X-Shirasagi-Version", SS.version, "utf-8").encoded
      f.puts Mail::Field.new("X-Shirasagi-Exported", @datetime.rfc822, "utf-8").encoded
      if data["files"].present?
        boundary = "--==_mimepart_#{SecureRandom.hex(16)}"
        f.puts "Content-Type: multipart/mixed;"
        f.puts " boundary=\"#{boundary}\""
        f.puts ""
        f.puts ""
        f.puts "--#{boundary}"
        write_body_to_eml(f, data)
        f.puts ""
        f.puts "--#{boundary}"
        data["files"].each do |file|
          f.puts "Content-Type: #{file['content_type']};"
          f.puts " filename=#{file['filename'].toutf8}"
          f.puts "Content-Transfer-Encoding: base64"
          f.puts "Content-Disposition: attachment;"
          f.puts " filename=#{file['filename'].toutf8};"
          f.puts " charset=UTF-8"
          f.puts ""
          f.puts file["base64"]
          f.puts ""
          f.puts "--#{boundary}--"
        end
      else
        write_body_to_eml(f, data)
      end
    end
  end

  def file_attributes(file)
    data = file.attributes
    data["base64"] = Base64.strict_encode64(::File.binread(file.path))
    data
  end

  def user_attributes(user)
    user.attributes.select { |k, v| %w(_id name).include?(k) }
  end

  def user_name_email(user)
    if user.email.present?
      "#{user.name} <#{user.email}>"
    else
      user.name
    end
  end

  def gen_message_id(data)
    @domain_for_message_id ||= site.canonical_domain.presence || SS.config.gws.canonical_domain.presence || "localhost.local"
    "<#{data["id"].to_s.presence || data["_id"].to_s.presence || SecureRandom.uuid}@#{@domain_for_message_id}>"
  end

  def write_body_to_eml(file, data)
    if data["format"] == "html"
      content_type = "text/html"
      base64 = Mail::Encodings::Base64.encode(data["html"].to_s)
    else
      content_type = "text/plain"
      base64 = Mail::Encodings::Base64.encode(data["text"].to_s)
    end

    file.puts "Content-Type: #{content_type}; charset=UTF-8"
    file.puts "Content-Transfer-Encoding: base64"
    file.puts ""
    file.puts base64
  end
end
