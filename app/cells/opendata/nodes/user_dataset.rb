# coding: utf-8
module Opendata::Nodes::UserDataset
  class ViewCell < Cell::Rails
    include Cms::NodeFilter::ViewCell
    helper ApplicationHelper
    append_view_path "app/views"

    public
      def index
        @items = Opendata::Dataset.site(@cur_site).
          order_by(updated: -1).
          page(params[:page]).
          per(20)

        @items.empty? ? "" : render
      end

      def show
        @model = Opendata::Dataset
        @item = @model.site(@cur_site).find(params[:id])

        render
      end
=begin
      def point
        @open = Opendata::Dataset
        @point = Opendata::DatasetPoint.new(point_params)
        @point.user_id = params[:id]
        @point.dataset_id = @open.site(@cur_site).find(params[:id]).id
        @point.site_id = @open.site(@cur_site).find(params[:id]).site_id
        @point.save

        cnt = @point.site(@cur_site).find_by(:dataset_id, @point.dataset_id).count
        @item = @open.site(@cur_site).find(params[:id])
        @item.point = 3
        render_update @item.update
      end
=end
      def new
        @model = Opendata::Dataset
        @item = @model.new

        render
      end

      def create
        set_model
        @item = @model.new get_params
        raise "403" unless @item.allowed?(create: @cur_user)

        location = opts[:location].presence || { action: :show, id: @item }

        if @item.save
          respond_to do |format|
            format.html { redirect_to location, notice: t(:saved) }
            format.json { render json: @item.to_json, status: :created }
          end
        else
          respond_to do |format|
            format.html { render file: :new }
            format.json { render json: @item.errors.full_messages, status: :unprocessable_entity }
          end
        end
      end

    private
      def point_params
        params.require(Opendata::DatasetPoint).permit(:id, :site_id, :user_id, :dataset_id)
      end

      def get_params
        params.require(Opendata::Dataset).permit(:id, :state, :name, :site_id, :user_id, :group_id, :categry_ids, :point, :text, :license)
      end

      def set_model
        @model = Opendata::Dataset
      end

  end
end
