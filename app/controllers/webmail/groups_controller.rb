class Webmail::GroupsController < ApplicationController
  include Webmail::BaseFilter
  include Sns::CrudFilter

  model Webmail::Group

  append_view_path "app/views/sys/groups"

  before_action :set_contact_email, only: [:show, :edit]
  before_action :set_default_settings, only: [:edit, :update]
  after_action :reload_nginx, only: [:create, :update, :destroy, :destroy_all]

  private

  def set_crumbs
    @crumbs << [t('mongoid.models.webmail/group'), action: :index]
  end

  def reload_nginx
    SS::Nginx::Config.new.write.reload_server
  end

  def set_contact_email
    @contact_email = @item.contact_email
  end

  def set_default_settings
    label = t('webmail.default_settings')
    conf = @cur_user.imap_default_settings

    @item.default_imap_setting = {
      from: @cur_user.name,
      address: @contact_email.presence || conf[:address],
      host: "#{label} / #{conf[:host]}",
      auth_type: "#{label} / #{conf[:auth_type]}",
      account: "#{label} / #{conf[:account]}",
      password: "#{label} / #{conf[:password].to_s.gsub(/./, '*')}"
    }
  end

  public

  def index
    raise "403" unless @model.allowed?(:edit, @cur_user)

    @items = @model.allow(:edit, @cur_user).
      state(params.dig(:s, :state)).
      search(params[:s]).
      page(params[:page]).per(50)
  end

  def new
    super
    set_default_settings
  end

  def create
    @item = @model.new get_params
    set_default_settings
    render_create @item.save
  end

  def destroy
    raise "403" unless @item.allowed?(:delete, @cur_user)
    render_destroy @item.disable
  end

  def destroy_all
    disable_all
  end
end
