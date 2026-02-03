#frozen_string_literal: true

module Workflow
  module_function

  def exceed_remind_limit?(duration, content, now: nil)
    now ||= Time.zone.now.change(usec: 0)
    now > content.updated + duration
  end

  def approvable_users(cur_site:, item:, criteria_or_array: nil)
    criteria_or_array ||= Cms::User.all.site(cur_site)
    criteria_or_array.select do |user|
      item.allowed?(:read, user, site: cur_site) && item.allowed?(:approve, user, site: cur_site) && user.enabled?
    end
  end
end
