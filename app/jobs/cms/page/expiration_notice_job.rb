class Cms::Page::ExpirationNoticeJob < Cms::ApplicationJob
  LOAD_FIELDS = %i[id site_id route name filename depth group_ids].freeze

  def perform
    unless site.page_expiration_enabled?
      Rails.logger.info("公開期限警告が無効です。")
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
    all_groups_in_expired_pages.each do |group|
      pages = select_expired_pages_in_group(group)
      next if pages.blank?

      mail = Cms::Mailer.expiration_page_notice(site, group, pages)
      mail.deliver_now if mail
    end
  end
end
