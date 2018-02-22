class Gws::Report::TrashesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Report::File

  navi_view 'gws/report/main/navi'
  append_view_path 'app/views/gws/report/files'

  before_action :set_forms
  before_action :set_search_params

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_report_label || t('modules.gws/report'), action: :index]
    @crumbs << [t('ss.links.trash'), action: :index]
  end

  def set_forms
    @forms ||= begin
      criteria = Gws::Report::Form.site(@cur_site)
      if params[:state] != 'preview'
        criteria = criteria.and_public
      end
      criteria = criteria.readable(@cur_user, site: @cur_site)
      criteria = criteria.order_by(order: 1, created: 1)
      criteria
    end
  end

  def set_search_params
    @s ||= begin
      s = OpenStruct.new params[:s]
      s.state = params[:state] if params[:state]
      s.cur_site = @cur_site
      s.cur_user = @cur_user
      s
    end
  end

  def set_items
    set_search_params
    @items ||= @model.site(@cur_site).allow(:trash, @cur_user, site: @cur_site).search(@s).only_deleted
  end

  def set_item
    set_items
    @item ||= begin
      item = @items.find(params[:id])
      item.attributes = fix_params
      item
    end
    @cur_form ||= @item.form if @item.present?
  rescue Mongoid::Errors::DocumentNotFound => e
    return render_destroy(true) if params[:action] == 'destroy'
    raise e
  end

  public

  def index
    set_items
    @items = @items.
      order_by(updated: -1, id: -1).
      page(params[:page]).per(50)
  end
end
