# coding: utf-8
module Opendata::Nodes::MyDataset
  class ViewCell < Cell::Rails
    include Cms::NodeFilter::ViewCell
    include Opendata::MypageFilter

    before_action :set_model
    before_action :set_item, only: [:show, :edit, :update, :delete, :destroy]

    protected
      def set_model
        @model = Opendata::Dataset
      end

      def set_item
        @item = @model.site(@cur_site).member(@cur_member).find params[:id]
        @item.attributes = fix_params
      end

      def fix_params
        { site_id: @cur_site.id, member_id: @cur_member.id, cur_node: @cur_node }
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
        @items = Opendata::Dataset.site(@cur_site).member(@cur_member).
          order_by(updated: -1).
          page(params[:page]).
          per(20)

        render
      end

      def show
        render
      end

      def new
        @item = @model.new
        render
      end

      def create
        @item = @model.new get_params

        if @item.save
          controller.redirect_to @cur_node.url, notice: t(:saved)
        else
          render file: :new
        end
      end

      def edit
        render
      end

      def update
        @item.attributes = get_params

        if @item.update
          controller.redirect_to "#{@cur_node.url}#{@item.id}", notice: t(:saved)
        else
          render file: :edit
        end
      end

      def delete
        render
      end

      def destroy
        if @item.destroy
          controller.redirect_to @cur_node.url, notice: t(:delete)
        else
          render file: :delete
        end
      end
  end
end
