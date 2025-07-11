class Gws::Frames::Columns::ShowComponent < ApplicationComponent
  include ActiveModel::Model
  include SS::ErrorMessagesFor

  attr_accessor :cur_site, :cur_user, :item, :ref, :column_type_options

  def render_column_edit
    path = item.column_form_partial_path
    unless path
      Rails.logger.warn { "#{item.class}(#{item.id}): unable to render" }
      return
    end
    view_context.render path, column: item, object_name: 'custom', value: nil
  end

  def edit_frame_path
    edit_gws_frames_column_path(id: item, ref: ref)
  end

  def edit_branch_frame_path
    edit_gws_frames_column_path(id: item, ref: ref, form: 'branch')
  end

  def edit_api_path
    edit_gws_apis_column_path(form_id: item.form, id: item, ref: ref)
  end

  def delete_frame_path
    gws_frames_column_path(id: item, ref: ref)
  end

  def change_type_frame_path
    change_type_gws_frames_column_path(id: item, ref: ref)
  end

  def see_class_list
    class_list = "see gws-column-see"
    if item.class.name.start_with?("Gws::Tabular")
      class_list += " gws-tabular-column-see"
    end
    class_list
  end
end
