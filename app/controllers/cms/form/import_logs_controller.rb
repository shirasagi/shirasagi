class Cms::Form::ImportLogsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  layout "cms/form_db"

  model Cms::FormDb::ImportLog

  before_action :set_db
  before_action :set_form
  before_action :set_item, only: [:show, :edit, :update, :delete, :destroy]

  private

  def set_crumbs
  end

  def set_db
    @db = Cms::FormDb.site(@cur_site).find(params[:db_id])
    @db.attributes = { cur_site: @cur_site, cur_user: @cur_user }
  end

  def set_form
    @form = @db.form
    @column_names = @form.column_names
  end

  def fix_params
    { cur_site: @cur_site, cur_user: @cur_user }
  end

  def get_params
    params.require(:item).permit(:name).merge(fix_params)
  rescue
    raise "400"
  end

  public

  def show
    render plain: @item.data, layout: false
  end
end
