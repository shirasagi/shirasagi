# coding: utf-8
module Opendata::Nodes::Dataset
  class EditCell < Cell::Rails
    include Cms::NodeFilter::EditCell
    #model Opendata::Node::Dataset
    model Opendata::Dataset

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

      def new
        @model = Opendata::Dataset
        @item = @model.new
        render partial: "app/views/opendata/datasets/form"

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
        render
      end

    private
      def get_params
        params.require(Opendata::Dataset).permit(:id, :state, :name, :site_id, :user_id, :group_id, :categry_ids, :point, :text, :license)
      end

      def set_model
        @model = Opendata::Dataset
      end

  end

  class ViewCell < Cell::Rails
    include Cms::NodeFilter::ViewCell

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

      def new
        @model = Opendata::Dataset
        @item = @model.new
        f = @item
        render partial: "/opendata/nodes/dataset/edit/form"

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
        render
      end

    private
      def get_params
        params.require(Opendata::Dataset).permit(:id, :state, :name, :site_id, :user_id, :group_id, :categry_ids, :point, :text, :license)
      end

      def set_model
        @model = Opendata::Dataset
      end

  end
end
