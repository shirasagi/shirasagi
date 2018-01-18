module Gws::Addon::Memo::Priority
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :priority, type: String
    permit_params :priority
  end

  def priority_options
    %w(1 2 3 4 5).map { |v| [ I18n.t("gws/memo.options.priority.#{v}"), v ] }
  end
end
