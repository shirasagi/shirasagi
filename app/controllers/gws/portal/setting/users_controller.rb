class Gws::Portal::Setting::UsersController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  helper Gws::PublicUserProfile

  model Gws::User

  prepend_view_path "app/views/sys/users"
  navi_view "gws/portal/main/navi"

  private

  def set_crumbs
    @crumbs << [t('gws/portal.user_portal'), { action: :index }]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def group_ids
    if params[:s].present? && params[:s][:group].present?
      @group = @cur_site.descendants.active.find(params[:s][:group]) rescue nil
    end
    @group ||= @cur_site
    @group_ids ||= @cur_site.descendants.active.in_group(@group).pluck(:id)
  end

  public

  def index
    raise "403" unless Gws::Portal::UserSetting.allowed?(:read, @cur_user, site: @cur_site, only: :other)

    @groups = @cur_site.descendants.active.tree_sort(root_name: @cur_site.name)

    @items = @model.site(@cur_site).
      state(params.dig(:s, :state)).
      in(group_ids: group_ids).
      search(params[:s]).
      order_by_title(@cur_site).
      page(params[:page]).per(50)
  end
end
