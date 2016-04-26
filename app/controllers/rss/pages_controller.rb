class Rss::PagesController < ApplicationController
  include Cms::BaseFilter
  include Cms::PageFilter
  include Workflow::PageFilter

  model Rss::Page

  append_view_path "app/views/cms/pages"
  navi_view "rss/main/navi"

  private
    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
    end

  public
    def import
      if !request.post?
        @item = Rss::Page.new
        return
      end

      Rss::ImportJob.bind(site_id: @cur_site.id, node_id: @cur_node.id, user_id: @cur_user.id).perform_later
      redirect_to({ action: :index }, { notice: t("rss.messages.job_started") })
    rescue => e
      Rails.logger.error("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
      @item.errors.add :base, e.to_s
    end
end
