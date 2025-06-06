class Gws::Tabular::Gws::ColumnsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::ColumnFilter2

  navi_view "gws/tabular/gws/main/conf_navi"
  self.form_model = Gws::Tabular::Form

  before_action :respond_404_if_cur_form_is_not_closed

  helper_method :cur_space

  DISABLE_COLUMNS = Set.new(%w(gws/title gws/section)).freeze

  private

  def set_crumbs
    @crumbs << [ t('modules.gws/tabular'), gws_tabular_gws_main_path ]
    @crumbs << [ t('mongoid.models.gws/tabular/space'), gws_tabular_gws_spaces_path ]
    @crumbs << [ cur_space.name, gws_tabular_gws_space_path(id: cur_space) ]
    @crumbs << [ t('mongoid.models.gws/tabular/form'), gws_tabular_gws_forms_path ]
    @crumbs << [ cur_form.name, gws_tabular_gws_form_path(id: cur_form) ]
  end

  def cur_space
    @cur_space ||= begin
      criteria = Gws::Tabular::Space.site(@cur_site)
      criteria = criteria.without_deleted
      criteria = criteria.allow(:read, @cur_user, site: @cur_site)
      criteria.find(params[:space])
    end
  end

  def cur_form
    @cur_form ||= begin
      criteria = form_model
      criteria = criteria.site(@cur_site)
      criteria = criteria.without_deleted
      criteria = criteria.allow(:read, @cur_user, site: @cur_site)
      criteria.find(params[:form_id])
    end
  end

  def respond_404_if_cur_form_is_not_closed
    raise "404" unless cur_form.closed?
  end

  def column_type_options
    @column_type_options ||= Gws::Tabular::Column.column_type_options(cur_form: cur_form)
  end

  def set_model
    model = self.class.model_class
    type = params[:type].to_s
    if type.present?
      plugin = Gws::Tabular::Column.find_plugin_by_path(type)
      raise '404' unless plugin

      model = plugin.model_class
      raise '404' unless model
    end

    @model = model
  end

  def show_component(item)
    Gws::Tabular::Gws::Columns::ShowComponent.new(
      cur_site: @cur_site, cur_user: @cur_user, cur_form: cur_form, item: item, ref: request.path,
      column_type_options: column_type_options)
  end

  def edit_component(item)
    Gws::Tabular::Gws::Columns::EditComponent.new(
      cur_site: @cur_site, cur_user: @cur_user, cur_form: cur_form, item: item, ref: request.path, new_item: true)
  end
end
