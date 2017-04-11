module Sns::PublicNoticeFilter
  extend ActiveSupport::Concern

  included do
    model Sys::Notice
  end

  def show
    raise "403" unless @item = @model.and_public.find(params[:id])
    render
  end
end
