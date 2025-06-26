class Gws::Frames::Columns::EditComponent < ApplicationComponent
  include ActiveModel::Model
  include SS::ErrorMessagesFor
  include SS::StimulusHelper

  attr_accessor :cur_site, :cur_user, :item, :ref
  attr_writer :new_item

  def new_item
    @new_item ||= false
  end

  def show_frame_path
    gws_frames_column_path(id: item, ref: ref)
  end

  def update_frame_path
    gws_frames_column_path(id: item)
  end

  def edit_api_path
    edit_gws_apis_column_path(form_id: item.form, id: item, ref: ref)
  end
end
