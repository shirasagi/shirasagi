module Gws::Facility::State::Daily::PlanHelper
  extend ActiveSupport::Concern

  def group_section_name(group_id)
    group = Gws::Group.find(group_id) rescue nil
    return if group.nil?

    group.section_name
  end
end
