class Gws::Tabular::Apis::Gws::FormsController < ApplicationController
  include Gws::ApiFilter

  model Gws::Tabular::Form

  helper_method :cur_space, :forms, :cur_form, :item_title

  private

  def cur_space
    @cur_space ||= begin
      criteria = Gws::Tabular::Space.site(@cur_site)
      criteria = criteria.without_deleted
      criteria = criteria.allow(:read, @cur_user, site: @cur_site)
      criteria.find(params[:space])
    end
  end

  def base_items
    @base_items ||= begin
      criteria = @model.site(@cur_site)
      criteria = criteria.space(cur_space)
      criteria = criteria.allow(:read, @cur_user, site: @cur_site)
      criteria = criteria.search(params[:s])
      criteria
    end
  end

  public

  def index
    @multi = params[:single].blank?
    @items = base_items.page(params[:page]).per(SS.max_items_per_page)
  end
end
