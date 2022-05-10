class Gws::Attendance::Apis::Management::UsersController < ApplicationController
  include Gws::ApiFilter

  model Gws::User

  before_action :set_manageable_groups
  before_action :set_search_params
  before_action :set_group
  before_action :set_custom_group

  append_view_path 'app/views/gws/apis/users'

  private

  def set_manageable_groups
    @manageable_groups ||= begin
      if Gws::Attendance::TimeCard.allowed?(:manage_all, @cur_user, site: @cur_site)
        Gws::Group.in_group(@cur_site).active
      elsif Gws::Attendance::TimeCard.allowed?(:manage_private, @cur_user, site: @cur_site)
        available_groups_for_user = @cur_user.groups.in_group(@cur_site).active
        Gws::Group.in_group(available_groups_for_user).active
      else
        Gws::Group.none
      end
    end
  end

  def set_search_params
    @s = OpenStruct.new(params[:s])
  end

  def set_group
    search_group = @s.group
    if search_group.present?
      @group = @manageable_groups.find(search_group) rescue nil
    end

    @group ||= @cur_group
    @group ||= @cur_site

    @groups = @manageable_groups.tree_sort(root_name: @cur_site.name)
  end

  def set_custom_group
    @custom_groups = Gws::CustomGroup.none
  end

  def group_ids
    @group_ids ||= @manageable_groups.in_group(@group).pluck(:id)
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
      criteria = @model.site(@cur_site).in(group_ids: group_ids)
    end

    @items = criteria.active.
      search(@s).
      order_by_title(@cur_site).
      page(params[:page]).per(50)
  end
end
