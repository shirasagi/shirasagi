class Cms::Page::ExpirationNoticeJob < Cms::ApplicationJob
  include Job::SS::TaskFilter

  LOAD_FIELDS = %i[id site_id route name filename depth group_ids].freeze

  self.task_class = Cms::Task
  self.task_name = "cms:page:expiration_notice"

  def perform(*_args)
    task.log "# #{site.name}"

    unless site.page_expiration_enabled?
      task.log "公開期限警告が無効です。"
      return
    end

    send_notice_mails
  end

  private

  def all_expired_pages
    @all_expired_pages ||= begin
      pages = []

      criteria = Cms::Page.all.site(site).and_public.lt(updated: site.page_expiration_at)
      all_ids = criteria.pluck(:id)
      all_ids.each_slice(20) do |ids|
        pages += criteria.only(*LOAD_FIELDS).in(id: ids).to_a
      end

      pages.each { |page| page.cur_site = site }

      pages
    end
  end

  def group_and_expired_pages_map
    @group_and_expired_pages_map ||= begin
      map = {}
      all_expired_pages.each do |page|
        page.group_ids.each do |group_id|
          map[group_id] ||= []
          map[group_id] << page
        end
      end
      map
    end
  end

  def all_groups_in_expired_pages
    @all_groups_in_expired_pages ||= begin
      all_group_ids = group_and_expired_pages_map.keys
      Cms::Group.all.site(site).in(id: all_group_ids).order_by(order: 1).to_a
    end
  end

  def select_expired_pages_in_group(group)
    group_and_expired_pages_map[group.id]
  end

  def send_notice_mails
    count = 0

    all_groups_in_expired_pages.each do |group|
      pages = select_expired_pages_in_group(group)
      next if pages.blank?

      mail = Cms::Mailer.expiration_page_notice(site, group, pages)
      if mail
        mail.deliver_now
        count += 1
      end
    end

    task.log "#{count.to_fs(:limited)} 通のメールを送信"
  end
end
