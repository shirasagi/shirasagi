class Cms::SnsPost::LineJob < Cms::ApplicationJob

  queue_as :external

  def perform(page_id)
    item = Cms::Page.find(page_id)
    Rails.logger.info("post to line : #{item.name}")
    item.post_to_line
  end
end
