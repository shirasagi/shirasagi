class Gws::Memo::MessageExportJob < Gws::ApplicationJob
  def perform(opts = {})
    @datetime = Time.zone.now
    @message_ids = opts[:message_ids]
    @root_url = opts[:root_url].to_s
    @output_zip = SS::DownloadJobFile.new(user, "gws-memo-messages-#{@datetime.strftime('%Y%m%d%H%M%S')}.zip")
    @output_dir = @output_zip.path.sub(::File.extname(@output_zip.path), "")
    @output_format = opts[:format].to_s.presence || "json"

    return if @message_ids.blank?

    FileUtils.rm_rf(@output_dir)
    FileUtils.rm_rf(@output_zip.path)
    FileUtils.mkdir_p(@output_dir)

    export_gws_memo_messages

    zip = Gws::Memo::MessageExport::Zip.new(@output_zip.path)
    zip.output_dir = @output_dir
    zip.output_format = @output_format
    zip.compress

    FileUtils.rm_rf(@output_dir)

    create_notify_message
  end

  def export_gws_memo_messages
    @message_ids.each do |id|
      item = Gws::Memo::Message.unscoped.find(id)
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

      if @output_format == "json"
        write_json(sanitize_filename("#{item.id}_#{item.display_subject}"), data.to_json)
      elsif @output_format == "eml"
        write_eml(sanitize_filename("#{item.id}_#{item.display_subject}"), data)
      end
    end
  end

  def create_notify_message
    item = Gws::Memo::Notice.new
    item.cur_site = site
    item.cur_user = user
    item.member_ids = [user.id]
    item.subject = I18n.t("gws/memo/message.export.subject")
    item.format = "text"
    item.text = I18n.t("gws/memo/message.export.notiry_message", link: ::File.join(@root_url, @output_zip.url))
    item.send_date = @datetime
    item.export = true
    item.save!
  end

  def write_json(name, data)
    File.write("#{@output_dir}/#{name}.json", data)
  end

  def write_eml(name, data)
    File.open("#{@output_dir}/#{name}.eml", "w") do |f|
      f.puts Mail::Field.new("Subject", data["subject"], "utf-8").encoded
      f.puts Mail::Field.new("From", data['from_name_email'], "utf-8").encoded
      f.puts Mail::Field.new("To", data['to_members_name_email'], "utf-8").encoded
      f.puts Mail::Field.new("Cc", data['cc_members_name_email'], "utf-8").encoded if data['cc_members_name_email'].present?
      if data["seen"].any?{|key, value| key == user.id.to_s}
        s_status = ["既読"]
      else
        s_status = ["未読"]
      end
      if data["star"].any?{|key, value| key == user.id.to_s}
        s_status << "スター"
      end
      f.puts Mail::Field.new("X-Shirasagi-Status", s_status, "utf-8").encoded
      if data["files"].present?
        boundary = "--==_mimepart_#{SecureRandom.hex(16)}"
        f.puts "Content-Type: multipart/mixed;"
        f.puts " boundary=\"#{boundary}\""
        f.puts ""
        f.puts ""
        f.puts "--#{boundary}"
        f.puts "Content-Type: text/plain; charset=UTF-8"
        f.puts ""
        f.puts data["text"]
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
        f.puts "Content-Type: text/plain; charset=UTF-8"
        f.puts ""
        f.puts data["text"]
      end
    end
  end

  def sanitize_filename(filename)
    filename.gsub(/[\<\>\:\"\/\\\|\?\*]/, '_').slice(0...250)
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
end
