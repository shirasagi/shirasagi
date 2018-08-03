class Event::IcalsController < ApplicationController
  include Cms::BaseFilter
  include Cms::PageFilter
  include Workflow::PageFilter

  model Event::Page

  append_view_path "app/views/cms/pages"
  navi_view "event/icals/navi"

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
  end

  public

  def import
    return if request.get?
    Event::Ical::ImportJob.bind(site_id: @cur_site.id, node_id: @cur_node.id, user_id: @cur_user.id).perform_later
    redirect_to({ action: :index }, { notice: t("rss.messages.job_started") })
  end
end
