class Gws::Workflow::TrashesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Workflow::File

  before_action :set_forms
  before_action :set_search_params

  navi_view 'gws/workflow/main/navi'
  append_view_path 'app/views/gws/workflow/files'

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_workflow_label || t('modules.gws/workflow'), gws_workflow_files_main_path]
    @crumbs << [t('ss.links.trash'), action: :index]
  end

  def set_forms
    @forms ||= begin
      criteria = Gws::Workflow::Form.site(@cur_site)
      if params[:state] != 'preview'
        criteria = criteria.and_public
      end
      criteria = criteria.readable(@cur_user, site: @cur_site)
      criteria = criteria.order_by(order: 1, created: 1)
      criteria
    end
  end

  def set_cur_form
    return if params[:form_id].blank? || params[:form_id] == 'default'
    set_forms
    @cur_form ||= @forms.find(params[:form_id])
  end

  def set_item
    super
    @cur_form ||= @item.form if @item.present?
  end

  def fix_params
    set_cur_form
    params = { cur_user: @cur_user, cur_site: @cur_site, state: 'closed' }
    params[:cur_form] = @cur_form if @cur_form
    params
  end

  def set_search_params
    @s = OpenStruct.new params[:s]
    @s.state = params[:state] if params[:state]
    @s.cur_site = @cur_site
    @s.cur_user = @cur_user
  end

  public

  def index
    @items = @model.site(@cur_site).allow(:trash, @cur_user, site: @cur_site).only_deleted.
      search(@s).
      page(params[:page]).per(50)
  end
end
