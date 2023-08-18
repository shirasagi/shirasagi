class Webmail::UserAccountsController < ApplicationController
  include Webmail::BaseFilter
  include Sns::CrudFilter

  model Webmail::User

  before_action :set_users
  before_action :set_user
  before_action :set_items
  before_action :set_item, only: [:show, :edit, :update, :delete, :destroy]
  before_action :set_default_settings, only: [:new, :create, :edit, :update]

  private

  def set_users
    @users = @model.all.allow(:read, @cur_user).state(params.dig(:s, :state)).search(params[:s])
  end

  def set_user
    @user = @users.find(params[:user_id])
  end

  def set_items
    @items = @user.imap_settings
  end

  def set_item
    @index = Integer(params[:id])
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
    conf = @user.imap_default_settings
    ssl_use = conf[:options][:usessl] ? "enabled" : "disabled"

    @defaults = {
      from: @user.name,
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

  def index
    redirect_to webmail_user_path(id: @user)
  end

  def show
    raise "403" unless @user.allowed?(:read, @cur_user)
    render
  end

  def new
    raise "403" unless @user.allowed?(:edit, @cur_user)
    @item = Webmail::ImapSetting.default.merge(pre_params.merge(fix_params).symbolize_keys)
  end

  def create
    raise "403" unless @user.allowed?(:edit, @cur_user)
    @item = Webmail::ImapSetting.default
    @item.merge!(get_params.to_h.symbolize_keys)
    if @item.invalid?
      render_create false
      return
    end

    new_imap_settings = []
    if @user.imap_settings.blank?
      # default account always exists at first.
      # so put it at 0 if it is missing.
      new_imap_settings << Webmail::ImapSetting.default
    else
      new_imap_settings += @user.imap_settings
    end
    new_imap_settings << @item.to_h
    @user.imap_settings = new_imap_settings.compact

    result = @user.save
    if !result
      SS::Model.copy_errors(@user, @item)
    end

    @index = @user.imap_settings.length - 1
    render_create result, { location: { action: :show, id: @index } }
  end

  def edit
    raise "403" unless @user.allowed?(:edit, @cur_user)
    render
  end

  def update
    raise "403" unless @user.allowed?(:edit, @cur_user)

    @item.merge!(get_params.to_h.symbolize_keys)
    if @item.invalid?
      render_create false
      return
    end

    new_imap_settings = @user.imap_settings.dup
    new_imap_settings[@index] = @item
    @user.imap_settings = new_imap_settings

    result = @user.save
    if !result
      SS::Model.copy_errors(@user, @item)
    end
    render_update result
  end

  def delete
    raise "403" unless @user.allowed?(:delete, @cur_user)

    if @index == 0
      redirect_to({ action: :show }, { notice: "既定のアカウントは削除できません。" })
      return
    end

    render
  end

  def destroy
    raise "403" unless @user.allowed?(:delete, @cur_user)

    if @index == 0
      redirect_to({ action: :show }, { notice: "既定のアカウントは削除できません。" })
      return
    end

    new_imap_settings = @user.imap_settings.dup
    new_imap_settings.delete_at(@index)
    @user.imap_settings = new_imap_settings

    result = @user.save
    if !result
      SS::Model.copy_errors(@user, @item)
    end
    render_destroy result
  end

  def test_connection
    setting = Webmail::ImapSetting.default
    setting.merge!(get_params.to_h.symbolize_keys)
    setting.set_imap_password
    setting.valid?

    @imap = Webmail::Imap::Base.new_by_user(@user, setting)
    if @imap.login
      render plain: "Login Success."
    else
      render plain: @imap.error
    end
  end
end
