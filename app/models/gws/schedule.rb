#frozen_string_literal: true

module Gws::Schedule
  MenuItem = Data.define(:label, :path_proc, :css_classes) do
    def initialize(label:, path_proc:, css_classes: nil)
      super
    end

    def path(*args, **kwargs)
      path_proc.call(*args, **kwargs)
    end
  end

  module_function

  def enum_menu_items(cur_site, cur_user)
    Enumerator.new do |y|
      # Personal Plans
      menu_item_gws_schedule_plans(cur_site, cur_user).try { y << _1 }

      # Facility Plans
      menu_item_gws_schedule_facilities(cur_site, cur_user).try { y << _1 }
      menu_item_gws_schedule_facility_approval_plans(cur_site, cur_user).try { y << _1 }

      # Several Utilities
      menu_item_gws_schedule_search(cur_site, cur_user).try { y << _1 }
      menu_item_gws_schedule_csv(cur_site, cur_user).try { y << _1 }
      menu_item_gws_schedule_trashes(cur_site, cur_user).try { y << _1 }

      # Managements
      menu_item_gws_schedule_holidays(cur_site, cur_user).try { y << _1 }
      menu_item_gws_schedule_categories(cur_site, cur_user).try { y << _1 }
      menu_item_gws_facility_categories(cur_site, cur_user).try { y << _1 }
      menu_item_gws_facility_items(cur_site, cur_user).try { y << _1 }
      menu_item_gws_facility_usage_main(cur_site, cur_user).try { y << _1 }
      menu_item_gws_facility_state_main(cur_site, cur_user).try { y << _1 }
    end
  end

  def enum_tab_items(cur_site, cur_user)
    Enumerator.new do |y|
      # Personal Plans
      menu_item_gws_schedule_plans(cur_site, cur_user).try { y << _1 }

      # Group Plans
      menu_items_gws_schedule_group_plans(cur_site, cur_user).try do |menu_items|
        menu_items.each { y << _1 }
      end
      menu_item_gws_schedule_all_groups(cur_site, cur_user).try { y << _1 }
      menu_items_gws_schedule_custom_group_plans(cur_site, cur_user).try do |menu_items|
        menu_items.each { y << _1 }
      end

      # Facility Plans
      menu_item_gws_schedule_facilities(cur_site, cur_user).try { y << _1 }
    end
  end

  def menu_item_gws_schedule_plans(cur_site, cur_user)
    return unless Gws::Schedule::Plan.allowed?(:use, cur_user, site: cur_site)
    return unless cur_site.schedule_personal_tab_visible?

    label = cur_site.effective_schedule_personal_tab_label
    helpers = Rails.application.routes.url_helpers
    path_proc = ->(*args, **kwargs) { helpers.gws_schedule_plans_path(*args, site: cur_site, **kwargs) }
    MenuItem.new(label: label, path_proc: path_proc, css_classes: %w(personal))
  end

  def menu_items_gws_schedule_group_plans(cur_site, cur_user)
    return unless Gws::Schedule::Plan.allowed?(:use, cur_user, site: cur_site)
    return unless cur_site.schedule_group_tab_visible?

    helpers = Rails.application.routes.url_helpers
    cur_user.schedule_tabs_visible_groups(cur_site).map do |group|
      path_proc = ->(*args, **kwargs) do
        helpers.gws_schedule_group_plans_path(*args, site: cur_site, group: group, **kwargs)
      end
      MenuItem.new(label: group.trailing_name, path_proc: path_proc, css_classes: %w(group))
    end
  end

  def menu_items_gws_schedule_custom_group_plans(cur_site, cur_user)
    return unless Gws::Schedule::Plan.allowed?(:use, cur_user, site: cur_site)
    return unless cur_site.schedule_custom_group_tab_visible?

    helpers = Rails.application.routes.url_helpers
    cur_user.schedule_tabs_visible_custom_groups(cur_site).filter_map do |g|
      next if g.member_ids.blank?

      path_proc = ->(*args, **kwargs) do
        helpers.gws_schedule_custom_group_plans_path(*args, site: cur_site, group: g, **kwargs)
      end
      MenuItem.new(label: g.name, path_proc: path_proc, css_classes: %w(custom-group))
    end
  end

  def menu_item_gws_schedule_all_groups(cur_site, cur_user)
    return unless Gws::Schedule::Plan.allowed?(:use, cur_user, site: cur_site)
    return unless cur_site.schedule_group_all_tab_visible?

    label = cur_site.effective_schedule_group_all_tab_label
    helpers = Rails.application.routes.url_helpers
    path_proc = ->(*args, **kwargs) { helpers.gws_schedule_all_groups_path(*args, site: cur_site, **kwargs) }
    MenuItem.new(label: label, path_proc: path_proc, css_classes: %w(group-all))
  end

  def menu_item_gws_schedule_facilities(cur_site, cur_user)
    return unless Gws::Schedule::Plan.allowed?(:use, cur_user, site: cur_site)
    return unless cur_site.schedule_facility_tab_visible?
    return unless cur_user.gws_role_permit_any?(cur_site, :use_private_gws_facility_plans)

    label = cur_site.effective_schedule_facility_tab_label
    helpers = Rails.application.routes.url_helpers
    path_proc = ->(*args, **kwargs) { helpers.gws_schedule_facilities_path(*args, site: cur_site, **kwargs) }
    MenuItem.new(label: label, path_proc: path_proc, css_classes: %w(facility))
  end

  def menu_item_gws_schedule_facility_approval_plans(cur_site, cur_user)
    return unless Gws::Schedule::Plan.allowed?(:use, cur_user, site: cur_site)
    return unless Gws::Schedule::Plan.allowed?(:edit, cur_user, site: cur_site)
    return unless cur_site.schedule_facility_tab_visible?
    return unless cur_user.gws_role_permit_any?(cur_site, :use_private_gws_facility_plans)

    helpers = Rails.application.routes.url_helpers
    path_proc = ->(*args, **kwargs) do
      helpers.gws_schedule_facility_approval_plans_path(*args, site: cur_site, **kwargs)
    end
    MenuItem.new(label: I18n.t('gws/schedule.navi.approve_facility_plan'), path_proc: path_proc)
  end

  def menu_item_gws_schedule_search(cur_site, cur_user)
    return unless Gws::Schedule::Plan.allowed?(:use, cur_user, site: cur_site)
    return unless cur_site.schedule_any_tab_visible?

    helpers = Rails.application.routes.url_helpers
    path_proc = ->(*args, **kwargs) { helpers.gws_schedule_search_path(*args, site: cur_site, **kwargs) }
    MenuItem.new(label: I18n.t('gws/schedule.tabs.search'), path_proc: path_proc)
  end

  def menu_item_gws_schedule_csv(cur_site, cur_user)
    return unless Gws::Schedule::Plan.allowed?(:use, cur_user, site: cur_site)
    return unless Gws::Schedule::Plan.allowed?(:edit, cur_user, site: cur_site)
    return unless cur_site.schedule_any_tab_visible?

    helpers = Rails.application.routes.url_helpers
    path_proc = ->(*args, **kwargs) { helpers.gws_schedule_csv_path(*args, site: cur_site, **kwargs) }
    MenuItem.new(label: I18n.t('ss.links.import'), path_proc: path_proc)
  end

  def menu_item_gws_schedule_trashes(cur_site, cur_user)
    return unless Gws::Schedule::Plan.allowed?(:use, cur_user, site: cur_site)
    return unless Gws::Schedule::Plan.allowed?(:trash, cur_user, site: cur_site)
    return unless cur_site.schedule_any_tab_visible?

    helpers = Rails.application.routes.url_helpers
    path_proc = ->(*args, **kwargs) { helpers.gws_schedule_trashes_path(*args, site: cur_site, **kwargs) }
    MenuItem.new(label: I18n.t('ss.links.trash'), path_proc: path_proc, css_classes: %w(trash))
  end

  def menu_item_gws_schedule_holidays(cur_site, cur_user)
    return unless Gws::Schedule::Holiday.allowed?(:read, cur_user, site: cur_site)

    helpers = Rails.application.routes.url_helpers
    path_proc = ->(*args, **kwargs) { helpers.gws_schedule_holidays_path(*args, site: cur_site, **kwargs) }
    MenuItem.new(label: I18n.t('gws/schedule.navi.holiday'), path_proc: path_proc, css_classes: %w(management))
  end

  def menu_item_gws_schedule_categories(cur_site, cur_user)
    return unless Gws::Schedule::Category.allowed?(:read, cur_user, site: cur_site)

    helpers = Rails.application.routes.url_helpers
    path_proc = ->(*args, **kwargs) { helpers.gws_schedule_categories_path(*args, site: cur_site, **kwargs) }
    MenuItem.new(label: I18n.t('gws/schedule.navi.category'), path_proc: path_proc, css_classes: %w(management))
  end

  def menu_item_gws_facility_categories(cur_site, cur_user)
    return unless Gws::Schedule::Category.allowed?(:read, cur_user, site: cur_site)

    helpers = Rails.application.routes.url_helpers
    path_proc = ->(*args, **kwargs) { helpers.gws_facility_categories_path(*args, site: cur_site, **kwargs) }
    MenuItem.new(label: I18n.t('gws/facility.navi.category'), path_proc: path_proc, css_classes: %w(management))
  end

  def menu_item_gws_facility_items(cur_site, cur_user)
    return unless Gws::Facility::Item.allowed?(:read, cur_user, site: cur_site)

    helpers = Rails.application.routes.url_helpers
    path_proc = ->(*args, **kwargs) { helpers.gws_facility_items_path(*args, site: cur_site, **kwargs) }
    MenuItem.new(label: I18n.t('gws/facility.navi.item'), path_proc: path_proc, css_classes: %w(management))
  end

  def menu_item_gws_facility_usage_main(cur_site, cur_user)
    return unless Gws::Facility::Item.allowed?(:edit, cur_user, site: cur_site)

    helpers = Rails.application.routes.url_helpers
    path_proc = ->(*args, **kwargs) { helpers.gws_facility_usage_main_path(*args, site: cur_site, **kwargs) }
    MenuItem.new(label: I18n.t('gws/facility.navi.usage'), path_proc: path_proc, css_classes: %w(management))
  end

  def menu_item_gws_facility_state_main(cur_site, cur_user)
    return unless Gws::Facility::Item.allowed?(:edit, cur_user, site: cur_site)

    helpers = Rails.application.routes.url_helpers
    path_proc = ->(*args, **kwargs) { helpers.gws_facility_state_main_path(*args, site: cur_site, **kwargs) }
    MenuItem.new(label: I18n.t('gws/facility.navi.state'), path_proc: path_proc, css_classes: %w(management))
  end
end
