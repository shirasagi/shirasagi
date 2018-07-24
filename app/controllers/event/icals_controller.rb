class Event::IcalsController < ApplicationController
  include Cms::BaseFilter
  include Cms::PageFilter
  include Workflow::PageFilter

  model Event::Ical

  append_view_path "app/views/cms/pages"
  navi_view "event/main/navi"

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
  end

  public

  def download
    csv = @model.site(@cur_site).node(@cur_node).to_csv.encode("SJIS", invalid: :replace, undef: :replace)
    filename = @model.to_s.tableize.gsub(/\//, "_")
    send_data csv, filename: "#{filename}_#{Time.zone.now.to_i}.csv"
  end

  def import
    return if request.get?
    Event::Ical::ImportJob.bind(site_id: @cur_site.id, node_id: @cur_node.id, user_id: @cur_user.id).perform_later
    redirect_to({ action: :index }, { notice: t("event.messages.job_started") })
  end
end
