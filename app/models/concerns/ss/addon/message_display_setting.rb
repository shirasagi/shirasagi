module SS::Addon::MessageDisplaySetting
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :message_list_column_order, type: String, default: "name_first"

    permit_params :message_list_column_order
    validates :message_list_column_order, inclusion: { in: %w(name_first subject_first), allow_blank: true }
  end

  def message_list_column_order_options
    %w(name_first subject_first).map do |v|
      [I18n.t("ss.options.message_list_column_order.#{v}"), v]
    end
  end

  def message_list_subject_first?
    message_list_column_order == "subject_first"
  end
end
