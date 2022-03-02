module Sys::Ad
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    include SS::Addon::LinkFile
    field :time, type: Integer
    field :width, type: Integer
    permit_params :time, :width
    after_save :file_state_update
  end

  private

  def file_state_update
    files.each { |file| file.update_attributes(state: "public") }
  end
end
