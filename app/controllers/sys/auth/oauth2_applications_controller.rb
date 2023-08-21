class Sys::Auth::OAuth2ApplicationsController < ApplicationController
  include Sys::BaseFilter
  include Sys::CrudFilter

  model SS::OAuth2::Application::Base

  navi_view "sys/auth/main/navi"
  menu_view "sys/crud/menu"

  before_action :preload_constants

  private

  def preload_constants
    SS::OAuth2::Application::Confidential
    SS::OAuth2::Application::Service
  end

  public

  def new
    type = params[:type]
    if type.blank?
      render "choose"
      return
    end

    case type
    when "confidential"
      @model = SS::OAuth2::Application::Confidential
      @item = SS::OAuth2::Application::Confidential.new
      @item.client_id = SecureRandom.urlsafe_base64(18)
      @item.client_secret = SecureRandom.urlsafe_base64(36)
      render template: "new"
    when "service"
      @model = SS::OAuth2::Application::Service
      @item = SS::OAuth2::Application::Service.new
      @item.client_id = SecureRandom.urlsafe_base64(18)
      render template: "new"
    else
      raise "404"
    end
  end

  def create
    type = params[:type]
    if type.blank?
      redirect_to action: :new
      return
    end

    case type
    when "confidential"
      @model = SS::OAuth2::Application::Confidential
      @item = SS::OAuth2::Application::Confidential.new get_params
    when "service"
      @model = SS::OAuth2::Application::Service
      @item = SS::OAuth2::Application::Service.new get_params
    else
      raise "404"
    end

    render_create @item.save
  end

  def show
    set_item
    @model = @item.class
    super
  end

  def edit
    set_item
    @model = @item.class
    super
  end

  def update
    set_item
    @model = @item.class
    super
  end
end
