module Sns::PublicNoticeFilter
  extend ActiveSupport::Concern

  included do
    model Sys::Notice
  end

  def show
    raise "403" unless @item = @model.and_public.find(params[:id])
    render
  end

  def frame_content
    raise "403" unless @item = @model.and_public.find(params[:id])
    render template: "frame_content", layout: false
  end
end
