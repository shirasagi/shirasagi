class Gws::Memo::ExportMessagesController < ApplicationController
  include Gws::Memo::ExportAndBackupFilter

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_memo_label || t('mongoid.models.gws/memo/message'), gws_memo_messages_path ]
    @crumbs << [t('gws/memo/message.export_messages'), gws_memo_export_messages_path ]
  end

  public

  def export
    message_ids = params.dig(:item, :message_ids)
    message_ids = message_ids.select(&:present?) if message_ids
    root_url = params.dig(:item, :root_url)
    export_filter = params.dig(:item, :export_filter)

    if export_filter != 'all' && message_ids.blank?
      @item = @model.new
      @item.errors.add(:base, I18n.t("gws/memo/message.errors.blank_message"))
      render template: "index"
      return
    end

    unless Gws::Memo::MessageExportJob.check_size_limit_per_user?(@cur_user.id)
      @item = @model.new
      @item.errors.add(:base, t('job.notice.size_limit_exceeded'))
      render template: "index"
      return
    end

    job_class = Gws::Memo::MessageExportJob.bind(site_id: @cur_site.id, user_id: @cur_user)
    job_class.perform_later(message_ids, root_url: root_url, export_filter: export_filter)
    render_create true, location: { action: :start_export }, notice: I18n.t("gws/memo/message.notice.start_export")
  end

  def start_export
  end
end
