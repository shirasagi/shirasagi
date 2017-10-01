class Webmail::Apis::AddressesController < ApplicationController
  include Sns::BaseFilter
  include SS::AjaxFilter

  model Webmail::Address

  before_action :set_group
  before_action :set_multi
  before_action :set_inherit_params

  private

  def set_group
    if params[:s].present? && params[:s][:group].present?
      @address_group = Webmail::AddressGroup.user(@cur_user).find(params[:s][:group]) rescue nil
    end

    @groups = Webmail::AddressGroup.user(@cur_user)
  end

  def set_multi
    @multi = params[:single].blank?
  end

  def set_inherit_params
    @inherit_keys = [:single]
  end

  public

  def index
    s_params = params[:s] || {}
    s_params[:address_group_id] = @address_group.id if @address_group.present?

    @items = @model.
      user(@cur_user).
      and_has_email.
      search(s_params).
      page(params[:page]).
      per(50)
  end
end
