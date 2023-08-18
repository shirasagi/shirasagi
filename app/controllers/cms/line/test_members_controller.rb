class Cms::Line::TestMembersController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::Line::TestMember

  navi_view "cms/line/main/navi"

  private

  def set_crumbs
    @crumbs << [t("cms.line_test_member"), cms_line_test_members_path]
  end

  def fix_params
    { cur_site: @cur_site, cur_user: @cur_user }
  end
end
