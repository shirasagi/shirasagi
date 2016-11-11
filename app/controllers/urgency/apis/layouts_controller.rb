class Urgency::Apis::LayoutsController < ApplicationController
  include Cms::ApiFilter

  model Cms::Layout

  before_action :set_single

  private
    def set_single
      @single = params[:single].present?
      @multi = !@single
    end

  public
    def index
      node_filenames, default_layout_ids = Urgency::Node::Layout.site(@cur_site).pluck(:filename, :urgency_default_layout_id).transpose
      Rails.logger.debug("node_filenames=#{node_filenames}")
      Rails.logger.debug("default_layout_ids=#{default_layout_ids}")

      @items = @model.site(@cur_site).
        where("$or" => node_filenames.map { |f| { filename: /^#{Regexp.escape(f)}/ } }).
        nin(id: default_layout_ids).
        search(params[:s]).
        order_by(name: 1).
        page(params[:page]).per(50)
    end
end
