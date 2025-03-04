#frozen_string_literal: true

class Cms::Frames::TempFiles::UploadsController < ApplicationController
  include Cms::BaseFilter

  model SS::File

  layout 'ss/item_frame'

  def index
    render
  end

  def preview
    files = params.require(:item).permit(files: %i[name size content_type])[:files]
    previews = []
    files.each do |file|
      preview = SS::TempFilePreview.new(cur_site: @cur_site, cur_user: @cur_user)
      preview.attributes = file
      preview.validate
      previews.push(preview)
    end

    render json: previews.map(&:to_h)
  end
end
