#frozen_string_literal: true

class Sns::Frames::TempFiles::UploadsController < ApplicationController
  include Sns::BaseFilter

  model SS::File

  layout 'ss/item_frame'

  def index
    render
  end

  def preview
    files = params.require(:item).permit(files: %i[name size content_type])[:files]
    previews = []
    files.each do |file|
      preview = SS::TempFilePreview.new(cur_user: @cur_user)
      preview.attributes = file
      preview.validate
      previews.push(preview)
    end

    render json: previews.map(&:to_h)
  end

  def create
    item_validator = SS::TempFileCreator.new(cur_user: @cur_user)
    if self.class.try(:only_image)
      item_validator.only_image = true
    end

    item_validator.attributes = params.require(:item).permit(:name, :filename, :resizing, :quality, :image_resizes_disabled, :in_file)
    if item_validator.invalid?
      json_data = item_validator.errors.full_messages
      render json: json_data, status: :unprocessable_entity, content_type: json_content_type
      return
    end

    result = item_validator.save
    unless result
      json_data = item_validator.errors.full_messages
      render json: json_data, status: :unprocessable_entity, content_type: json_content_type
      return
    end

    json_data = item_validator.work_item.as_json({ methods: %i[humanized_name image? basename extname url thumb_url] })
    json_data[:sanitizer_state] = sanitizer_state = item_validator.work_item.try(:sanitizer_state) || 'none'
    json_data[:sanitizer_state_label] = SS::UploadPolicy.sanitizer_state_label(sanitizer_state)
    render json: json_data, status: :created, content_type: json_content_type
  end
end
