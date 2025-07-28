class Cms::Apis::PagesController < ApplicationController
  include Cms::ApiFilter
  include Cms::Apis::PageFilter

  model Cms::Page

  before_action :set_partner_sites

  private

  def set_partner_sites
    @partner_sites ||= Cms::Site.without_deleted.where(partner_site_ids: @cur_site.id).to_a
  end

  public

  def index
    @items = @items.
      order_by(_id: -1).
      page(params[:page]).per(50)

    if params[:layout] == "iframe"
      render layout: "ss/ajax_in_iframe"
    end
  end

  def routes
    @items = @model.routes
  end
end
