module Gws::Schedule::UserSetting
  extend ActiveSupport::Concern
  extend Gws::UserSetting

  included do
    attr_accessor :in_schedule_tabs_group_ids,
                  :in_schedule_tabs_group_ids_all,
                  :in_schedule_tabs_custom_group_ids,
                  :in_schedule_tabs_custom_group_ids_all

    # ids
    # - empty:  show
    # - exists: hide
    embeds_ids :schedule_tabs_groups, class_name: 'Gws::Group'
    embeds_ids :schedule_tabs_custom_groups, class_name: 'Gws::CustomGroup'

    permit_params in_schedule_tabs_group_ids: [],
                  in_schedule_tabs_group_ids_all: [],
                  in_schedule_tabs_custom_group_ids: [],
                  in_schedule_tabs_custom_group_ids_all: []

    before_validation :set_schedule_tabs_group_ids, if: -> { in_schedule_tabs_group_ids_all.present? }
    before_validation :set_schedule_tabs_custom_group_ids, if: -> { in_schedule_tabs_custom_group_ids_all.present? }
  end

  def schedule_tabs_visible_groups(site)
    groups.in_group(site).nin(id: schedule_tabs_group_ids)
  end

  def schedule_tabs_visible_custom_groups(site)
    custom_groups.site(site).readable(self, site).nin(id: schedule_tabs_custom_group_ids)
  end

  private
    def set_schedule_tabs_group_ids
      inc = (in_schedule_tabs_group_ids_all.to_a & in_schedule_tabs_group_ids.to_a).map { |m| m.to_i }
      dec = (in_schedule_tabs_group_ids_all.to_a - in_schedule_tabs_group_ids.to_a).map { |m| m.to_i }
      ids = (schedule_tabs_group_ids.to_a - inc + dec).map { |m| m.to_i }.uniq.compact
      self.schedule_tabs_group_ids = ids
    end

    def set_schedule_tabs_custom_group_ids
      inc = (in_schedule_tabs_custom_group_ids_all.to_a & in_schedule_tabs_custom_group_ids.to_a).map { |m| m.to_i }
      dec = (in_schedule_tabs_custom_group_ids_all.to_a - in_schedule_tabs_custom_group_ids.to_a).map { |m| m.to_i }
      ids = (schedule_tabs_custom_group_ids.to_a - inc + dec).map { |m| m.to_i }.uniq.compact
      self.schedule_tabs_custom_group_ids = ids
    end
end
