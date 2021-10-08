class Webmail::ImportMailsController < ApplicationController
  include Webmail::BaseFilter
  include SS::CrudFilter

  model Webmail::MailImporter
  menu_view nil

  private

  def set_crumbs
    @crumbs << [t("webmail.settings.import_mails"), { action: :index } ]
    @webmail_other_account_path = :webmail_import_mails_path
  end

  def fix_params
    { cur_user: @cur_user }
  end

  def permit_fields
  end

  def set_item
    @item = @cur_user
  end

  public

  def index
    if @webmail_mode == :group
      redirect_to webmail_mails_path(webmail_mode: @webmail_mode)
      return
    end

    @item = @model.new
  end

  def import
    if @webmail_mode == :group
      redirect_to webmail_mails_path(webmail_mode: @webmail_mode)
      return
    end

    @item = @model.new

    file = params.dig(:item, :in_file)
    if file.nil?
      @item.errors.add :in_file, :blank
      render template: "index"
      return
    end

    file_type = SS::MimeType.find(file.original_filename, nil)
    if !@model::SUPPORTED_MIME_TYPES.include?(file_type)
      @item.errors.add :in_file, :invalid_file_type
      render template: "index"
      return
    end

    @item.cur_user = @cur_user
    @item.account = params[:account].to_i
    @item.in_file = file
    @item.import_mails

    render_opts = { location: { action: :index }, render: { template: "index" }, notice: I18n.t("webmail.import.start_import") }
    render_create @item.errors.blank?, render_opts
  end

  def start_import
  end
end
