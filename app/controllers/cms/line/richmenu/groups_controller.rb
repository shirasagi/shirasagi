class Cms::Line::Richmenu::GroupsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::Line::Richmenu::Group

  navi_view "cms/line/main/navi"

  private

  def set_crumbs
    @crumbs << [t("cms.line_richmenu"), cms_line_richmenu_groups_path]
  end

  def fix_params
    { cur_site: @cur_site, cur_user: @cur_user }
  end

  public

  def apply
    @task = Cms::Task.find_or_create_by name: "cms:line_apply_richmenu", site_id: @cur_site.id
    @item = @model.active_group

    if request.get?
      respond_to do |format|
        format.html { render }
        format.json { render template: "ss/tasks/index", content_type: json_content_type, locals: { item: @task } }
      end
      return
    end

    Cms::Line::ApplyRichmenuJob.bind(site_id: @cur_site, user_id: @cur_user).perform_later
    redirect_to({ action: :apply }, { notice: I18n.t("ss.notice.started_apply") })
  end
end
