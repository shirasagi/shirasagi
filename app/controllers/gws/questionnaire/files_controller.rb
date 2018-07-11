class Gws::Questionnaire::FilesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Questionnaire::File

  before_action :set_forms
  before_action :set_cur_form, only: %i[new create]
  before_action :set_search_params
  before_action :set_items
  # before_action :redirect_to_appropriate_state, only: %i[show]

  navi_view "gws/questionnaire/main/navi"

  private

  def set_crumbs
    set_cur_form
    @crumbs << [t('modules.gws/questionnaire'), gws_questionnaire_main_path]
    @crumbs << [t('ss.navi.readable'), gws_questionnaire_readables_path]
    @crumbs << [@cur_form.name, action: :new]
  end

  def set_forms
    @forms ||= begin
      criteria = Gws::Questionnaire::Form.site(@cur_site)
      if params[:state] != 'preview'
        criteria = criteria.and_public
      end
      criteria = criteria.readable(@cur_user, site: @cur_site)
      criteria = criteria.order_by(order: 1, created: 1)
      criteria
    end
  end

  def set_cur_form
    raise '404' if params[:readable_id].blank?
    set_forms
    @cur_form ||= @forms.find(params[:readable_id])
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

  # def redirect_to_appropriate_state
  #   return if params[:state] != 'redirect'
  #
  #   if @item.user_ids.include?(@cur_user.id) || (@item.group_ids & @cur_user.group_ids).present?
  #     if @item.public?
  #       state = 'sent'
  #     else
  #       state = 'closed'
  #     end
  #   elsif @item.member_ids.include?(@cur_user.id)
  #     state = 'inbox'
  #   else
  #     state = 'readable'
  #   end
  #
  #   raise '404' if state.blank?
  #   redirect_to(state: state)
  # end

  def fix_params
    set_cur_form
    { cur_site: @cur_site, cur_user: @cur_user, cur_form: @cur_form }
  end

  def set_items
    @items ||= begin
      items = @model.site(@cur_site).form(@cur_form)
      if @cur_form.file_closed?
        items = items.user(@cur_user)
      end
      items
    end
  end

  public

  def index
    @items = @items.search(@s).page(params[:page]).per(50)
  end

  def new
    raise '403' unless @cur_form.allowed?(:read, @cur_user, site: @cur_site)

    @item = @model.new pre_params.merge(fix_params)
    render_opts = { file: :new }
    render_opts[:layout] = false if request.xhr?
    render render_opts
  end

  def create
    raise '403' unless @cur_form.allowed?(:read, @cur_user, site: @cur_site)

    @item = @model.new fix_params
    @item.name = @cur_form.name
    custom = params.require(:custom)
    new_column_values = @cur_form.build_column_values(custom)
    @item.update_column_values(new_column_values)

    render_opts = { location: gws_questionnaire_readables_path }
    if params[:continuous].present?
      render_opts[:location] = { action: :new }
    end

    render_create(@item.save, render_opts)
  end
end
