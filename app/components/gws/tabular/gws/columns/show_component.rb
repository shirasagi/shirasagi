class Gws::Tabular::Gws::Columns::ShowComponent < Gws::Frames::Columns::ShowComponent
  attr_accessor :cur_form

  def column_type_options
    @column_type_options ||= begin
      items = {}

      Gws::Tabular::Column.route_options.each do |name, path|
        mod = path.sub(/\/.*/, '')
        items[mod] = { name: t("modules.#{mod}"), items: [] } if !items[mod]
        items[mod][:items] << [ name.sub(/.*\//, ''), path ]
      end

      items
    end
  end

  def render_column_edit
    renderer = item.value_renderer(
      nil, :form, form: OpenStruct.new(object_name: 'dummy'), cur_site: cur_site, cur_user: cur_user, item: item)
    view_context.render renderer
  end

  def edit_frame_path
    edit_gws_tabular_frames_gws_column_path(form: cur_form, id: item, ref: ref)
  end

  def edit_branch_frame_path
    edit_gws_tabular_frames_gws_column_path(id: item, ref: ref, form: 'branch')
  end

  # def edit_api_path
  #   edit_gws_apis_column_path(form_id: item.form, id: item, ref: ref)
  # end

  def delete_frame_path
    gws_tabular_frames_gws_column_path(form: cur_form, id: item, ref: ref)
  end

  def change_type_frame_path
    change_type_gws_tabular_frames_gws_column_path(form: cur_form, id: item, ref: ref)
  end
end
