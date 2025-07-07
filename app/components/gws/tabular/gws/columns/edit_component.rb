class Gws::Tabular::Gws::Columns::EditComponent < Gws::Frames::Columns::EditComponent
  attr_accessor :cur_form

  def show_frame_path
    gws_tabular_frames_gws_column_path(form: cur_form, id: item, ref: ref)
  end

  def edit_frame_path
    edit_gws_tabular_frames_gws_column_path(form: cur_form, id: item, ref: ref)
  end

  # def edit_api_path
  #   edit_gws_apis_column_path(form_id: item.form, id: item, ref: ref)
  # end

  def update_frame_path
    gws_tabular_frames_gws_column_path(form: cur_form, id: item)
  end
end
