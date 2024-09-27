class Lsorg::NodesController < ApplicationController
  include Cms::BaseFilter
  include Cms::NodeFilter

  model Lsorg::Node::Page

  navi_view "lsorg/main/navi"

  private

  def redirect_url
    { action: :show, id: @item.id }
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
  end

  def pre_params
    { route: "lsorg/page" }
  end

  def set_task
    @task = Cms::Task.find_or_create_by name: task_name, site_id: @cur_site.id, node_id: @cur_node.id
  end

  def task_name
    "lsorg:import"
  end

  def job_bindings
    {
      site_id: @cur_site.id,
      node_id: @cur_node.id,
      user_id: @cur_user.id
    }
  end

  public

  def import
    raise "403" unless @cur_user.cms_role_permit_any?(@cur_site, :import_lsorg_node_pages)

    set_task

    if request.get? || request.head?
      respond_to do |format|
        format.html { render }
        format.json { render template: "ss/tasks/index", content_type: json_content_type, locals: { item: @task } }
      end
      return
    end

    Lsorg::ImportGroupsJob.bind(job_bindings).perform_later({})
    redirect_to({ action: :import }, { notice: I18n.t("ss.notice.started_import") })
  end
end
