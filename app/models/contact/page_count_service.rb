class Contact::PageCountService
  include ActiveModel::Model

  cattr_accessor :expires_in, instance_accessor: false
  self.expires_in = 1.hour

  attr_accessor :cur_site, :cur_user

  def render(group_id:, contact_id:)
    return helpers.tag.span("na", title: "Not Available") if cur_site.blank?

    count = count_map["#{group_id}:#{contact_id}"]
    count ||= 0

    label = helpers.tag.span(I18n.t("contact.pages_used", count: count), class: "count", data: { count: count })
    return label if count == 0

    path = url_helpers.cms_group_pages_path(site: cur_site.id, group_id: group_id, contact_id: contact_id)
    helpers.link_to(label, path, data: { turbo: false })
  end

  private

  def helpers
    @helpers ||= ApplicationController.helpers
  end

  def url_helpers
    @url_helpers ||= Rails.application.routes.url_helpers
  end

  def task
    @task ||= Cms::Task.all.order_by(id: 1).find_or_create_by(site_id: cur_site.id, name: Contact::PageCountJob::task_name)
  end

  def require_refreshing?(now = nil)
    path = Contact::PageCountJob.page_count_path(task)
    return true if !::File.exist?(path) || ::File.size(path).zero?

    mtime = ::File.mtime(path).in_time_zone
    now ||= Time.zone.now

    mtime + self.class.expires_in < now
  end

  def count_map
    return @count_map if instance_variable_defined?(:@count_map)
    @count_map = load_count_map
  end

  def load_count_map
    3.times do |i|
      break unless require_refreshing?

      sleep 5 * i if i > 0
      Contact::PageCountJob.bind(site_id: cur_site.id).perform_now
    end

    @map = {}

    path = Contact::PageCountJob.page_count_path(task)
    return @map if !::File.exist?(path) || ::File.size(path).zero?

    ::File.readlines(path).each do |line|
      next if line.start_with?("#")

      json = JSON.parse(line.strip)
      group_id = json["group_id"]
      contact_id = json["contact_id"]
      count = json["count"]

      @map["#{group_id}:#{contact_id}"] = count
    end

    @map
  end
end
