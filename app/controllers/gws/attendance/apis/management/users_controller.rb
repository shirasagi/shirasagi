class Gws::Attendance::Apis::Management::UsersController < ApplicationController
  include Gws::ApiFilter

  model Gws::User

  before_action :set_manageable_groups
  before_action :set_group
  before_action :set_custom_group

  append_view_path 'app/views/gws/apis/users'

  private

  def set_manageable_groups
    if Gws::Attendance::TimeCard.allowed?(:manage_all, @cur_user, site: @cur_site)
      @manageable_groups = Gws::Group.in_group(@cur_site).active
    elsif Gws::Attendance::TimeCard.allowed?(:manage_private, @cur_user, site: @cur_site)
      @manageable_groups = Gws::Group.in_group(@cur_group).active
    else
      @manageable_groups = Gws::Group.none
    end
  end

  def set_group
    if params.dig(:s, :group).present?
      @group = @manageable_groups.find(params.dig(:s, :group)) rescue nil
      @group ||= @cur_group
    else
      @group = @cur_group
    end

    @groups = @manageable_groups.tree_sort(root_name: @cur_site.name)
  end

  def set_custom_group
    @custom_groups = Gws::CustomGroup.none
  end

  def group_ids
    @group_ids ||= @manageable_groups.pluck(:id)
  end

  def self.local_prefixes
    super + ['gws/apis/users']
  end
  private_class_method :local_prefixes

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
