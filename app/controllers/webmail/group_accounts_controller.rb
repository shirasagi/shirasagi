class Webmail::GroupAccountsController < ApplicationController
  include Webmail::BaseFilter
  include Sns::CrudFilter

  model Webmail::Group

  before_action :set_groups
  before_action :set_group
  before_action :set_items
  before_action :set_item, only: [:show, :edit, :update, :delete, :destroy]
  before_action :set_default_settings, only: [:new, :create, :edit, :update]

  private

  def set_groups
    @groups = @model.all.allow(:read, @cur_user).state(params.dig(:s, :state)).search(params[:s])
  end

  def set_group
    @group = @groups.find(params[:group_id])
  end

  def set_items
    @items = @group.imap_settings
  end

  def set_item
    @index = 0
    @item = @items[@index]
    if @index == 0
      @item ||= Webmail::ImapSetting.default.merge(
        name: @group.section_name, from: @group.section_name
      )
    end

    raise "404" if @item.nil?
  end

  def permit_fields
    @model.permitted_fields.find { |param| param.is_a?(Hash) && param.key?(:imap_settings) }[:imap_settings]
  end

  def set_default_settings
    label = t('webmail.default_settings')
    conf = @group.imap_default_setting
    ssl_use = conf[:options][:usessl] ? "enabled" : "disabled"

    @defaults = {
      name: @group.section_name,
      from: @group.section_name,
      address: @group.contact_email,
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
    raise "404" if @group.imap_settings.blank?
    raise "403" unless @group.allowed?(:read, @cur_user)
    render
  end

  def edit
    raise "403" unless @group.allowed?(:edit, @cur_user)
    render
  end

  def update
    raise "403" unless @group.allowed?(:edit, @cur_user)

    @item.merge!(get_params.to_h.symbolize_keys)
    @item.set_imap_password
    if @item.invalid?(:group)
      render_update false
      return
    end

    @group.imap_settings = [ @item ]

    result = @group.save
    if !result
      SS::Model.copy_errors(@group, @item)
    end
    render_update result
  end

  def delete
    raise "403" unless @group.allowed?(:delete, @cur_user)
    render
  end

  def destroy
    raise "403" unless @group.allowed?(:delete, @cur_user)

    @group.imap_settings = []

    result = @group.save
    if !result
      SS::Model.copy_errors(@group, @item)
    end
    render_destroy result, location: webmail_group_path(id: @group)
  end

  def test_connection
    setting = Webmail::ImapSetting.default
    setting.merge!(get_params.to_h.symbolize_keys)
    setting.set_imap_password
    setting.valid?(:group)

    @imap = Webmail::Imap::Base.new_by_group(@group, setting)
    if @imap.login
      render plain: "Login Success."
    else
      render plain: @imap.error
    end
  end
end
