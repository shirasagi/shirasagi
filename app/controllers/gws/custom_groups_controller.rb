class Gws::CustomGroupsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::CustomGroup

  navi_view "gws/main/conf_navi"

  before_action :set_default_readable_setting, only: [:new]

  private

  def set_crumbs
    @crumbs << [t("mongoid.models.gws/custom_group"), gws_custom_groups_path]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def set_default_readable_setting
    @default_readable_setting = proc do
      @item.readable_setting_range = "select"
      @item.readable_group_ids = [ @cur_group.id ]
      @item.readable_member_ids = [ @cur_user.id ]
      @item.readable_custom_group_ids = []
    end
  end

  public

  def index
    @items = @model.site(@cur_site).
      allow(:read, @cur_user, site: @cur_site).
      search(params[:s]).
      page(params[:page]).per(50)
  end
end
