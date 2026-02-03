module Workflow
  module_function

  def exceed_remind_limit?(duration, content, now: nil)
    now ||= Time.zone.now.change(usec: 0)
    now > content.updated + duration
  end

  def approvable_users(cur_site:, item:, criteria: nil)
    criteria ||= Cms::User.all.site(cur_site)
    if item.is_a?(Cms::GroupPermission) && !criteria.is_a?(Array)
      # Cms::GroupPermission を include している場合、最適化されたメソッドを実行
      return _approvable_users_cms_group_permission(cur_site: cur_site, item: item, criteria: criteria)
    end

    criteria.select do |user|
      item.allowed?(:read, user, site: cur_site) && item.allowed?(:approve, user, site: cur_site) && user.enabled?
    end
  end

  # Cms::GroupPermission を include している場合、最適化されたメソッドを実行
  def _approvable_users_cms_group_permission(cur_site:, item:, criteria:)
    model = item.class

    permissions = [ model.permission_action || :read, model.permission_action || :approve ].flat_map do |action|
      [ "#{action}_other_#{model.permission_name}", "#{action}_private_#{model.permission_name}" ]
    end

    role_ids = Cms::Role.site(cur_site).in(permissions: permissions).pluck(:id)
    criteria = criteria.in(cms_role_ids: role_ids)
    criteria.select do |user|
      item.allowed?(:read, user, site: cur_site) && item.allowed?(:approve, user, site: cur_site) && user.enabled?
    end
  end
end
