class Gws::Tabular::Frames::Gws::ColumnsController < Gws::Frames::ColumnsController

  private

  def cur_space
    @cur_space ||= begin
      criteria = Gws::Tabular::Space.site(@cur_site)
      criteria = criteria.without_deleted
      criteria = criteria.readable(@cur_user, site: @cur_site)
      criteria.find(params[:space])
    end
  end

  def forms
    @forms ||= begin
      criteria = Gws::Tabular::Form.site(@cur_site)
      criteria = criteria.space(cur_space)
      criteria = criteria.without_deleted
      criteria = criteria.readable(@cur_user, site: @cur_site)
      criteria.reorder(order: 1, id: 1)
    end
  end

  def cur_form
    @cur_form ||= forms.find(params[:form])
  end

  def column_type_options
    @column_type_options ||= Gws::Tabular::Column.column_type_options(cur_form: cur_form)
  end

  def show_component
    Gws::Tabular::Gws::Columns::ShowComponent.new(
      cur_site: @cur_site, cur_user: @cur_user, cur_form: cur_form, item: item, ref: ref,
      column_type_options: column_type_options)
  end

  def edit_component
    Gws::Tabular::Gws::Columns::EditComponent.new(
      cur_site: @cur_site, cur_user: @cur_user, cur_form: cur_form, item: item, ref: ref)
  end

  def find_new_plugin(new_route)
    Gws::Tabular::Column.find_plugin_by_path(new_route)
  end
end
