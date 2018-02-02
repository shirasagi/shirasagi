class Gws::Memo::Apis::PersonalAddressesController < ApplicationController
  include Sns::BaseFilter
  include SS::AjaxFilter

  model Webmail::Address

  before_action :set_fragment
  before_action :set_group
  before_action :set_multi
  before_action :set_inherit_params

  private

  def set_fragment
    @fragment = params[:fragment].to_s
  end

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

    s_group_params = params[:s_group] || {}

    @items = @model.
      user(@cur_user).
      and_has_member.
      search(s_params).
      page(params[:page]).
      per(50)

    @group_items = @groups.search(s_group_params).page(params[:page]).per(50)
  end
end
