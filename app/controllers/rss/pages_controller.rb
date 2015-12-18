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

      Rss::ImportJob.call_async(@cur_site.host, @cur_node.id, @cur_user.id) do |job|
        job.site_id = @cur_site.id
        job.user_id = @cur_user.id
      end
      SS::RakeRunner.run_async "job:run", "RAILS_ENV=#{Rails.env}"
      redirect_to({ action: :index }, { notice: t("rss.messages.job_started") })
    rescue => e
      Rails.logger.error("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
      @item.errors.add :base, e.to_s
    end
end
