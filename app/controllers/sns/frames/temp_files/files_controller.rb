#frozen_string_literal: true

class Sns::Frames::TempFiles::FilesController < ApplicationController
  include Sns::BaseFilter
  include Sns::CrudFilter

  model SS::File

  layout 'ss/item_frame'

  before_action :set_search_params

  helper_method :items

  private

  def set_search_params
    @s ||= begin
      s = SS::TempFileSearchParam.new(cur_user: @cur_user)
      if params.key?(:s)
        s.attributes = params[:s].permit(:keyword, types: [])
      end
      if s.types.blank?
        s.types = %w(temp_file)
      end
      s.validate
      s
    end
  end

  def base_items
    set_search_params
    @base_items ||= @s.query(SS::File, SS::File.unscoped)
  end

  def items
    @items ||= base_items.reorder(filename: 1).page(params[:page]).per(20)
  end

  def crud_redirect_url
    url_for(action: :index, cid: cur_node, s: params[:s].try(:to_unsafe_h))
  end

  def set_item
    @item ||= begin
      item = SS::File.find(params[:id])
      item = item.becomes_with_model
      @model = item.class
      item
    end
  end

  public

  def index
    render
  end

  def select
    set_item
    if !@item.is_a?(SS::TempFile) && !@item.is_a?(Cms::TempFile)
      @item = @item.copy(cur_user: @cur_user)
    end

    respond_to do |format|
      format.html do
        component = SS::FileViewV2Component.new(cur_user: @cur_user, file: @item)
        component.animated = "animate__animated animate__bounceIn"
        render component, layout: false
      end
      format.json do
        json_data = @item.as_json({ methods: %i[humanized_name image? basename extname url thumb_url] })
        json_data["sanitizer_state"] = sanitizer_state = @item.try(:sanitizer_state) || 'none'
        json_data["sanitizer_state_label"] = SS::UploadPolicy.sanitizer_state_label(sanitizer_state)
        render json: json_data, status: :created, content_type: json_content_type
      end
    end
  end
end
