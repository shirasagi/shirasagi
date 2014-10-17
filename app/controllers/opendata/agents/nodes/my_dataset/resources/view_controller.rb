module Opendata::Agents::Nodes::MyDataset::Resources
  class ViewController < ApplicationController
    include Cms::NodeFilter::View
    include Opendata::MypageFilter

    before_action :set_dataset
    before_action :set_model
    before_action :set_item, only: [:show, :edit, :update, :delete, :destroy]

    protected
      def dataset
        @dataset ||= Opendata::Dataset.site(@cur_site).find params[:dataset_id]
      end

      def set_dataset
        raise "403" if dataset.member_id != @cur_member.id
        @dataset_url  = "#{@cur_node.url}#{@dataset.id}/"
        @resource_url = "#{@dataset_url}resources/"
      end

      def set_model
        @model = Opendata::Resource
      end

      def set_item
        @item = dataset.resources.find params[:id]
        @item_url = "#{@resource_url}#{@item.id}/"
      end

      def fix_params
        {}
      end

      def pre_params
        {}
      end

      def permit_fields
        @model.permitted_fields
      end

      def get_params
        params.require(:item).permit(permit_fields).merge(fix_params)
      end

    public
      def index
      @items = @dataset.resources.
        order_by(name: 1).
        page(params[:page]).per(50)

        render
      end

      def show
        render
      end

      def download
        @item = @dataset.resources.find params[:resource_id]
        send_data @item.file.data, type: @item.content_type, filename: @item.filename, disposition: :attachment
      end

      def new
        @item = @model.new
        render
      end

      def create
        @item = @dataset.resources.create get_params

        if @item.valid?
          redirect_to "#{@dataset_url}resources/", notice: t(:saved)
        else
          render action: :new
        end
      end

      def download
        @item = dataset.resources.find params[:resource_id]
        send_data @item.file.data, type: @item.content_type, filename: @item.filename, disposition: :attachment
      end

      def edit
        render
      end

      def update
        @item.attributes = get_params

        if @item.update
          redirect_to "#{@dataset_url}resources/#{@item.id}", notice: t(:saved)
        else
          render action: :edit
        end
      end

      def delete
        render
      end

      def destroy
        if @item.destroy
          redirect_to @resource_url, notice: t(:delete)
        else
          render action: :delete
        end
      end
  end
end
