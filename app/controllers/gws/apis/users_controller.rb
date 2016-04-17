class Gws::Apis::UsersController < ApplicationController
  include Gws::ApiFilter

  model Gws::User

  before_action :set_group

  private
    def set_group
      @group = @cur_user.groups.in_group(@cur_site).map(&:id).first
      @group = params[:s][:group] if params[:s].present? && params[:s][:group].present?

      @groups = Gws::Group.site(@cur_site).reduce([]) do |ret, g|
        indent = "&nbsp;" * g.name.scan('/').size * 4
        ret << [ indent.html_safe + g.trailing_name, g.id ]
      end.to_a
    end

    def group_ids
      group = Gws::Group.find(@group)
      Gws::Group.in_group(group).map(&:id)
    end

  public
    def index
      @multi = params[:single].blank?

      @items = @model.site(@cur_site).
        in(group_ids: group_ids).
        search(params[:s]).
        order_by_title(@cur_site).
        page(params[:page]).per(50)
    end
end
