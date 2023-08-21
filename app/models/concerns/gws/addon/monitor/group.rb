module Gws::Addon::Monitor::Group
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    embeds_ids :attend_groups, class_name: "Gws::Group"
    permit_params attend_group_ids: []

    validates :attend_group_ids, presence: true, if: -> { topic.nil? }

    scope :and_attended, ->(user, opts = {}) {
      or_conds = attended_conditions(user, opts)
      where("$and" => [{ "$or" => or_conds }])
    }
  end

  module ClassMethods
    def attended_conditions(user, opts = {})
      [
        { :attend_group_ids => opts[:group].id }
      ]
    end
  end

  def attended?(group)
    attend_group_ids.include?(group.id)
  end
end
