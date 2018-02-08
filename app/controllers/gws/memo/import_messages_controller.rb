class Gws::Memo::ImportMessagesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Memo::MessageImporter

  navi_view "gws/memo/messages/navi"
  menu_view nil

  before_action :deny_with_auth

  private

  def deny_with_auth
    raise "403" unless Gws::Memo::Message.allowed?(:edit, @cur_user, site: @cur_site)
  end

  def set_crumbs
    @crumbs << [@cur_site.menu_memo_label || t('mongoid.models.gws/memo/message'), gws_memo_messages_path ]
    @crumbs << [t('gws/memo/message.import_messages'), gws_memo_import_messages_path ]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  public

  def index
    @model.new
  end

  def import
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
    @item.import_messages

    render_create true, location: { action: :import }, notice: I18n.t("gws/memo/message.notice.start_import")
  end
end
