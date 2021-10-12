class Webmail::AccountsController < ApplicationController
  include Webmail::BaseFilter
  include Sns::CrudFilter

  model Webmail::User

  before_action :check_group_imap_permissions, if: ->{ @webmail_mode == :group }
  before_action :set_items
  before_action :set_item, only: [:show, :edit, :update, :delete, :destroy]
  before_action :set_default_settings, only: [:new, :create, :edit, :update]

  private

  def check_group_imap_permissions
    redirect_to webmail_mails_path(webmail_mode: @webmail_mode, account: params[:account])
  end

  def set_crumbs
    @crumbs << [t('webmail.settings.account'), { action: :show } ]
    @webmail_other_account_path = :webmail_account_path
  end

  def set_items
    @items = @cur_user.imap_settings
  end

  def set_item
    @index = Integer(params[:account])
    @item = @items[@index]
    if @index == 0
      @item ||= Webmail::ImapSetting.default
    end

    raise "404" if @item.nil?
  end

  def permit_fields
    @model.permitted_fields.find { |param| param.is_a?(Hash) && param.key?(:imap_settings) }[:imap_settings]
  end

  def set_default_settings
    label = t('webmail.default_settings')
    conf = @cur_user.imap_default_settings
    ssl_use = conf[:options][:usessl] ? "enabled" : "disabled"

    @defaults = {
      from: @cur_user.name,
      address: conf[:address],
      host: "#{label} / #{conf[:host]}",
      port: "#{label} / #{conf[:options][:port]}",
      ssl_use: "#{label} / #{I18n.t("webmail.options.imap_ssl_use.#{ssl_use}")}",
      auth_type: "#{label} / #{conf[:auth_type]}",
      account: "#{label} / #{conf[:account]}",
      password: "#{label} / #{conf[:password].to_s.gsub(/./, '*')}"
    }
  end

  public

  def show
    raise "403" unless @cur_user.webmail_permitted_any?(:read_webmail_accounts)

    if @webmail_mode == :group
      redirect_to webmail_mails_path(webmail_mode: @webmail_mode)
      return
    end
    render
  end

  def edit
    raise "403" unless @cur_user.webmail_permitted_any?(:edit_webmail_accounts)

    if @webmail_mode == :group
      redirect_to webmail_mails_path(webmail_mode: @webmail_mode)
      return
    end
    render
  end

  def update
    raise "403" unless @cur_user.webmail_permitted_any?(:edit_webmail_accounts)

    @item.merge!(get_params.to_h.symbolize_keys)
    if @item.invalid?
      render_create false
      return
    end

    new_imap_settings = @cur_user.imap_settings.dup
    new_imap_settings[@index] = @item
    @cur_user.imap_settings = new_imap_settings

    result = @cur_user.save
    if !result
      SS::Model.copy_errors(@cur_user, @item)
    end
    render_update result
  end

  def test_connection
    setting = Webmail::ImapSetting.default
    setting.merge!(get_params.to_h.symbolize_keys)
    setting.set_imap_password
    setting.valid?

    @imap = Webmail::Imap::Base.new_by_user(@cur_user, setting)
    if @imap.login
      render plain: "Login Success."
    else
      render plain: @imap.error
    end
  end
end
