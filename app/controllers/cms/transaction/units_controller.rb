class Cms::Transaction::UnitsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::Transaction::Unit

  navi_view "cms/main/navi"

  before_action :set_plan

  def index
    redirect_to cms_transaction_plan_path(id: @plan)
  end

  private

  def set_crumbs
  end

  def set_plan
    @plan = Cms::Transaction::Plan.site(@cur_site).find(params[:plan_id])
  end

  def set_model
    @type = params[:type].presence
    raise "400" if @type.nil?

    @type = nil if @type == "-"
    @model = @type ? "#{Cms::Transaction::Unit}::#{@type.classify}".constantize : Cms::Transaction::Unit::Base
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, plan: @plan }
  end

  #def crud_redirect_url
  #  cms_transaction_plan_path(id: @plan)
  #end
end
