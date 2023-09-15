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
    Rails.logger.info("#{@exported_items.to_s(:delimied)} 件のメッセージをエクスポートしました。")

    if @exported_items == 0
      create_notify_message(failed: true)
      return
    end

    create_notify_message
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
        item.write_as_eml(user, f, site: site)
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
        item = item.to_list_message if item.list_message?

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
end
