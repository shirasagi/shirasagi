class Gws::Memo::BackupMessagesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Memo::Message

  navi_view "gws/memo/messages/navi"
  menu_view nil

  before_action :deny_with_auth
  before_action :check_permission

  private

  def deny_with_auth
    raise "403" unless @model.allowed?(:edit, @cur_user, site: @cur_site)
  end

  def set_crumbs
    @crumbs << [@cur_site.menu_memo_label || t('mongoid.models.gws/memo/message'), gws_memo_messages_path ]
    @crumbs << [t('gws/memo/message.backup_messages'), gws_memo_backup_messages_path ]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def check_permission
    raise "403" unless @cur_user.gws_role_permit_any?(@cur_site, :backup_gws_memo_messages)
  end

  public

  def index
    @item = @model.new
  end

  def backup
    message_ids = params.dig(:item, :message_ids)
    message_ids = message_ids.select(&:present?) if message_ids
    root_url = params.dig(:item, :root_url)
    backup_filter = params.dig(:item, :backup_filter)
    format = params.dig(:item, :format)

    if backup_filter != 'all' && message_ids.blank?
      @item = @model.new
      @item.errors.add(:base, I18n.t("gws/memo/message.errors.blank_message"))
      render file: :index
      return
    end

    unless Gws::Memo::MessageBackupJob.check_size_limit_per_user?(@cur_user.id)
      @item = @model.new
      @item.errors.add(:base, t('job.notice.size_limit_exceeded'))
      render file: :index
      return
    end

    job_class = Gws::Memo::MessageBackupJob.bind(site_id: @cur_site.id, user_id: @cur_user)
    job_class.perform_later(message_ids, root_url: root_url, backup_filter: backup_filter, format: format)
    render_create true, location: { action: :start_backup }, notice: I18n.t("gws/memo/message.notice.start_backup")
  end

  def start_backup
  end
end
