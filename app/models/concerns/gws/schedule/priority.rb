module Gws::Schedule::Priority
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    field :priority, type: Integer
    permit_params :priority
    validates :priority, inclusion: { in: [1, 2, 3, 4, 5], allow_blank: true }
  end

  def priority_options
    %w(1 2 3 4 5).map do |v|
      [I18n.t("gws/schedule.options.priority.#{v}"), v]
    end
  end
end
