class Gws::Apis::UsersController < ApplicationController
  include Gws::ApiFilter

  model Gws::User

  before_action :set_group

  private
    def set_group
      if params[:s].present? && params[:s][:group].present?
        @group = @cur_site.descendants.active.find(params[:s][:group])
      else
        @group = @cur_user.groups.active.in_group(@cur_site).first
      end

      @groups = @cur_site.descendants.active
    end

    def group_ids
      @cur_site.descendants.active.in_group(@group).pluck(:id)
    end

  public
    def index
      @multi = params[:single].blank?

      @items = @model.site(@cur_site).
        active.
        in(group_ids: group_ids).
        search(params[:s]).
        order_by_title(@cur_site).
        page(params[:page]).per(50)
    end
end
