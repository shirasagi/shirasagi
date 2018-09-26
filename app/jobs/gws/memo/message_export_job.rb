class Gws::Memo::MessageExportJob < Gws::ApplicationJob
  def perform(opts = {})
    @datetime = Time.zone.now
    @message_ids = opts[:message_ids]
    @root_url = opts[:root_url].to_s
    @output_zip = SS::DownloadJobFile.new(user, "gws-memo-messages-#{@datetime.strftime('%Y%m%d%H%M%S')}.zip")
    @output_dir = @output_zip.path.sub(::File.extname(@output_zip.path), "")
    @output_format = opts[:format]

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
      end
      if item.cc_members.present?
        data['cc_members'] = item.cc_members.map { |u| user_attributes(u) }
      end
      if item.bcc_members.present?
        data['bcc_members'] = item.bcc_members.select{ |u| u.id == user.id }.map { |u| user_attributes(u) }
      end
      if item.files.present?
        data['files'] = item.files.map { |file| file_attributes(file) }
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
    item.save!
  end

  def write_json(name, data)
    File.write("#{@output_dir}/#{name}.json", data)
  end

  def write_eml(name, data)
    File.open("#{@output_dir}/#{name}.eml", "w") do |f|
      f.puts "Subject: #{data['subject']}"
      f.puts "From: #{data['from_member_name']}"
      f.puts "To: #{data['to_member_name']}"
      f.puts "Cc: #{data['cc_member_name']}"
      if data["seen"].any?{|key, value| key == user.id.to_s}
        s_status = "既読"
      else
        s_status = "未読"
      end
      if data["star"].any?{|key, value| key == user.id.to_s}
        s_status += ", スター"
      end
      f.puts "X-Shirasagi-Status: #{s_status}"
      if data["files"].present?
        boundary = "------------#{SecureRandom.hex(16)}"
        f.puts "Content-Type: multipart/mixed; boundary=\"#{boundary}\""
        f.puts ""
        f.puts "This is a multi-part message in MIME format."
        f.puts boundary
        f.puts "Content-Type: text/plain; charset=UTF-8"
        f.puts data["text"]
        data["files"].each do |file|
          f.puts boundary
          f.puts "Content-Type: #{file['content_type']}"
          f.puts " name=\"=?UTF-8?B?#{file['filename'].toutf8}\""
          f.puts "Content-Transfer-Encoding: base64"
          f.puts "Content-Disposition: attachment;"
          f.puts " filename*=iso-2022-jp''#{file['filename'].tosjis}\""
          f.puts ""
          f.puts file["base64"]
          f.puts boundary
        end
      else
        f.puts "Content-Type: text/plain; charset=UTF-8"
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
end
