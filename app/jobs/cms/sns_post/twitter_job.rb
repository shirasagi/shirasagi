class Cms::SnsPost::TwitterJob < Cms::ApplicationJob

  queue_as :external

  def perform(page_id)
    item = Cms::Page.find(page_id)
    Rails.logger.info("post to twitter : #{item.name}")

    if SS.config.cms.enable_lgwan
      Lgwan::Support.pull_private_files(item)
    end

    item.post_to_twitter
  end
end
