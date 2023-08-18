class Cms::SnsPost::TwitterJob < Cms::ApplicationJob

  queue_as :external

  def perform(page_id)
    item = Cms::Page.find(page_id)
    Rails.logger.info("post to twitter : #{item.name}")

    SS::Lgwan.pull_private_files(item) if SS::Lgwan.web?
    item.post_to_twitter
  end
end
