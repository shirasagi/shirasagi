class Gws::StaffRecord::GroupsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::StaffRecord::Group

  navi_view "gws/staff_record/settings/navi"

  private

  def set_crumbs
    @crumbs << [t("mongoid.models.gws/staff_record/group_setting"), gws_staff_record_setting_path]
    @crumbs << [t("mongoid.models.gws/staff_record/group"), gws_staff_record_groups_path]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  public

  def index
    @items = @model.site(@cur_site).
      allow(:read, @cur_user, site: @cur_site).
      search(params[:s]).
      page(params[:page]).per(50)
  end
end
