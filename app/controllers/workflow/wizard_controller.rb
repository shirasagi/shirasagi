class Workflow::WizardController < ApplicationController
  include Cms::SearchFilter

  before_action :set_route, only: [:approver_setting]
  before_action :set_item, only: [:approver_setting]

  private
    def set_model
      @model = Cms::Page
    end

    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site, cur_node: false }
    end

    def set_route
      route_id = params[:route_id]
      if "my_group" == route_id
        @route = nil
      else
        @route = Cms::Workflow::Route.find(params[:route_id])
      end
      # TODO: check route
    end

    def set_item
      @item = @model.find(params[:id]).becomes_with_route
      @item.attributes = fix_params
    end

  public
    def index
      render layout: false
    end

    def approver_setting
      if @route.present?
        if @item.apply_workflow?(@route)
          render file: "approver_setting_multi", layout: false
        else
          render json: @item.errors.full_messages, status: :bad_request
        end
      else
        render layout: false
      end
    end
end
