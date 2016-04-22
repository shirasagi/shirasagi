class Gws::Apis::UsersController < ApplicationController
  include Gws::ApiFilter

  model Gws::User

  before_action :set_group
  before_action :set_custom_group

  private
    def set_group
      if params[:s].present? && params[:s][:group].present?
        @group = @cur_site.descendants.active.find(params[:s][:group]) rescue nil
        @group ||= @cur_site
      else
        @group = @cur_user.groups.active.in_group(@cur_site).first
      end

      @groups = @cur_site.descendants.active
    end

    def set_custom_group
      @custom_groups = Gws::CustomGroup.site(@cur_site).readable(@cur_user, @cur_site)

      if params[:s].present? && params[:s][:custom_group].present?
        @custom_group = Gws::CustomGroup.site(@cur_site).find(params[:s][:custom_group]) rescue nil
      end
    end

    def group_ids
      @group_ids ||= @cur_site.descendants.active.in_group(@group).pluck(:id)
    end

  public
    def index
      @multi = params[:single].blank?

      if @custom_group.present?
        criteria = @custom_group.members
      else
        criteria = @model.site(@cur_site)
      end

      @items = criteria.active.
        in(group_ids: group_ids).
        search(params[:s]).
        order_by_title(@cur_site).
        page(params[:page]).per(50)
    end
end
