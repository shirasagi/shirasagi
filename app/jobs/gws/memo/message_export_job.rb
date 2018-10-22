class Gws::Memo::MessageExportJob < Gws::ApplicationJob
  def perform(opts = {})
    @datetime = Time.zone.now
    @message_ids = opts[:message_ids]
    @root_url = opts[:root_url].to_s
    @output_zip = SS::DownloadJobFile.new(user, "gws-memo-messages-#{@datetime.strftime('%Y%m%d%H%M%S')}.zip")
    @output_dir = @output_zip.path.sub(::File.extname(@output_zip.path), "")

    return if @message_ids.blank?

    FileUtils.rm_rf(@output_dir)
    FileUtils.rm_rf(@output_zip.path)
    FileUtils.mkdir_p(@output_dir)

    export_gws_memo_messages

    zip = Gws::Memo::MessageExport::Zip.new(@output_zip.path)
    zip.output_dir = @output_dir
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

      write_json(sanitize_filename("#{item.id}_#{item.display_subject}"), data.to_json)
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
