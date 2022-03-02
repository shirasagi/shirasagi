class Cms::Form::DocsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  layout "cms/form_db"

  model Article::Page

  before_action :set_db
  before_action :set_form
  before_action :require_node, only: [:new, :create, :edit, :update, :import]
  before_action :set_item, only: [:show, :edit, :update, :delete, :destroy]

  private

  def set_crumbs
  end

  def set_db
    @db = Cms::FormDb.find(params[:db_id])
    @db.attributes = { cur_site: @cur_site, cur_user: @cur_user }
  end

  def set_form
    @form = @db.form
    @column_names = @form.column_names
  end

  def fix_params
    { cur_site: @cur_site, cur_user: @cur_user, cur_node: @db.node }
  end

  def get_params
    params.require(:item).permit(:name).merge(fix_params)
  rescue
    raise "400"
  end

  def get_column_params
    columns = params.require(:item).permit(column_values: [:name, :value])
    columns[:column_values].to_unsafe_h.map { |k, v| [v['name'], v['value']] }.to_h
  end

  def require_node
    return if @db.node

    @item = @model.new
    @item.errors.add :base, I18n.t('errors.messages.cms_form_db_required_node')
    render template: 'errors', layout: true
  end

  public

  def index
    @items = @db.pages.order(name: 1)
      .page(params[:page]).per(50)
  end

  def create
    @item = @model.new get_params
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site, node: @db.node)
    render_create @db.save_page(@item, get_column_params)
  end

  def update
    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    render_update @db.save_page(@item, get_column_params)
  end

  def download_all
    return unless request.post?

    @items = @db.pages.order(name: 1)

    csv_params = params.require(:item).permit(:encoding)
    csv = Cms::FormDb.export_csv(@form, @items, csv_params)
    send_data csv, filename: "pages_#{Time.zone.now.to_i}.csv"
  end

  def import
    @item = @db
    return unless request.post?

    in_params = params.require(:item).permit(:in_file)

    @db.in_file = in_params[:in_file]
    return unless @db.import_csv

    redirect_to({ action: :import }, { notice: 'インポートしました。' })
  end
end
