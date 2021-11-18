class Cms::SnsPost::LineJob < Cms::ApplicationJob

  queue_as :external

  def perform(page_id)
    item = Cms::Page.find(page_id)
    Rails.logger.info("post to line : #{item.name}")

    if SS.config.cms.enable_lgwan
      Lgwan::Support.pull_private_files(item)
    end

    item.post_to_line
  end
end
