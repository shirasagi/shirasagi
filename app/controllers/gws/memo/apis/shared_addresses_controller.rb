class Gws::Memo::Apis::SharedAddressesController < ApplicationController
  include Gws::ApiFilter

  MAX_ITEMS_PER_PAGE = 50

  model Gws::SharedAddress::Address

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
      @address_group = Gws::SharedAddress::Group.find(params[:s][:group]) rescue nil
    end

    @groups = Gws::SharedAddress::Group.site(@cur_site).readable(@cur_user, site: @cur_site)
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

    @items = @model.site(@cur_site).
      and_has_member.
      readable(@cur_user, site: @cur_site).
      without_deleted.
      search(s_params).
      page(params[:page]).
      per(MAX_ITEMS_PER_PAGE)

    @group_items = @groups.search(s_group_params).page(params[:group_page]).per(MAX_ITEMS_PER_PAGE)
  end
end
