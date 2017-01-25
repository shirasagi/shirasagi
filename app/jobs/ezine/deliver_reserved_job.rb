class Ezine::DeliverReservedJob < Cms::ApplicationJob
  include Ezine::BaseJob

  # Deliver a page as Emails.
  #
  # 1ページをメールとして送信する。
  # 配信予約日時が設定されている場合、条件を満たせば送信される。
  #
  def perform(now = Time.zone.now)
    Ezine::Page.site(site).where(:completed => false, :deliver_date.ne => nil, :deliver_date.lte => now).each do |page|
      Ezine::Task.ready(site_id: site.id, page_id: page.id, name: 'ezine:deliver') do |task|
        deliver_one_page(page, task)
      end
    end
  end
end
