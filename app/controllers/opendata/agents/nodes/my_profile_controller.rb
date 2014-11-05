class Opendata::Agents::Nodes::MyProfileController < ApplicationController
  include Cms::NodeFilter::View
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
        redirect_to @cur_node.url, notice: t("views.notice.saved")
      else
        render action: :edit
      end
    end
end
