# coding: utf-8
module Opendata::Nodes::MyProfile
  class EditCell < Cell::Rails
    include Cms::NodeFilter::EditCell
    model Opendata::Node::MyProfile
  end

  class ViewCell < Cell::Rails
    include Cms::NodeFilter::ViewCell
    include Opendata::MypageFilter

    before_action :set_model
    before_action :set_item, only: [:show, :edit, :update, :delete, :destroy]

    protected
      def set_model
        @model = Cms::Member
      end

      def set_item
        @item = @cur_member
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
      def show
        render
      end

      def edit
        render
      end

      def update
        @item.attributes = get_params

        if @item.update
          controller.redirect_to @cur_node.url, notice: t(:saved)
        else
          render file: :edit
        end
      end
  end
end
