#frozen_string_literal: true

class Cms::Frames::TempFiles::UploadsController < ApplicationController
  include Cms::BaseFilter

  model SS::File

  layout 'ss/item_frame'

  helper_method :cur_node

  private

  def cur_node
    return @cur_node if instance_variable_defined?(:@cur_node)

    cid = params[:cid].to_s
    if cid.blank?
      @cur_node = nil
      return @cur_node
    end

    @cur_node = Cms::Node.site(@cur_site).find(cid)
  end

  public

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
