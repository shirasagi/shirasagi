class Workflow::SearchApproversController < ApplicationController
  include Cms::ApiFilter

  model Cms::User

  private
    def group_id
      default_group_id = @cur_user.group_ids.first
      return default_group_id if params[:s].blank?
      return default_group_id if params[:s][:group].blank?

      group_id = params[:s][:group]
      case group_id
      when "false" then
        false
      else
        group_id.to_i
      end
    end

    def group_options
      Cms::Group.site(@cur_site).reduce([]) do |ret, g|
        ret << [ g.name, g.id ]
      end.to_a
    end

  public
    def index
      @level = params[:level]
      @group_id = group_id
      @group_options = group_options
      criteria = @model.site(@cur_site).search(params[:s])
      criteria = criteria.in(group_ids: [ @group_id ]) if @group_id
      @items = criteria.order_by(_id: 1).page(params[:page]).per(50)
    end
end
