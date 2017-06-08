class Ezine::DeliverJob < Cms::ApplicationJob
  include Job::SS::TaskFilter
  include Ezine::BaseJob

  self.task_class = Ezine::Task

  # Deliver a page as Emails.
  #
  # 1ページをメールとして送信する。
  # 配信予約日時が設定されている場合、条件を満たせば送信される。
  #
  def perform
    return if page.nil?
    return if page.deliver_date && Time.zone.now < page.deliver_date
    if page.completed?
      Rails.logger.debug("#{page.filename}: delivering page has been completed.")
      return
    end
    deliver_one_page(page, task)
  end

  private
  def task_cond
    { site_id: site_id, page_id: page_id, name: 'ezine:deliver' }
  end
end
