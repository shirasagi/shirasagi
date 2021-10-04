class Gws::Memo::RestoreMessagesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Memo::MessageRestorer

  navi_view "gws/memo/messages/navi"
  menu_view nil

  before_action :deny_with_auth
  before_action :check_permission

  private

  def deny_with_auth
    raise "403" unless Gws::Memo::Message.allowed?(:edit, @cur_user, site: @cur_site)
  end

  def set_crumbs
    @crumbs << [@cur_site.menu_memo_label || t('mongoid.models.gws/memo/message'), gws_memo_messages_path ]
    @crumbs << [t('gws/memo/message.restore_messages'), gws_memo_restore_messages_path ]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def check_permission
    raise "403" unless @cur_user.gws_role_permit_any?(@cur_site, :restore_gws_memo_messages)
  end

  public

  def index
    @model.new
  end

  def restore
    @item = @model.new

    file = params.dig(:item, :in_file)
    if file.nil?
      @item.errors.add :in_file, :blank
      render file: :index
      return
    end
    if ::File.extname(file.original_filename) != ".zip"
      @item.errors.add :in_file, :invalid_file_type
      render file: :index
      return
    end

    @item.cur_site = @cur_site
    @item.cur_user = @cur_user
    @item.in_file = file
    @item.restore_messages

    render_create true, location: { action: :restore }, notice: I18n.t("gws/memo/message.notice.start_restore")
  end
end
