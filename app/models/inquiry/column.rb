class Inquiry::Column
  include SS::Document
  include SS::Reference::Site
  include Cms::SitePermission
  include Inquiry::Addon::InputSetting

  seqid :id
  field :node_id, type: Integer
  field :state, type: String, default: "public"
  field :name, type: String
  field :html, type: String, default: ""
  field :order, type: Integer, default: 0

  belongs_to :node, foreign_key: :node_id, class_name: "Inquiry::Node::Form"

  permit_params :id, :node_id, :state, :name, :html, :order

  validates :node_id, :state, :name, presence: true

  def answer_data(opts = {})
    node.answers.where(opts).
      map { |ans| ans.data.entries.select { |data| data.column_id == id } }.flatten
  end

  def state_options
    [
      [I18n.t('views.options.state.public'), 'public'],
      [I18n.t('views.options.state.closed'), 'closed'],
    ]
  end

  def order
    value = self[:order].to_i
    value < 0 ? 0 : value
  end

  def validate_data(answer, data)
    if required?
      if data.blank? || data.value.blank?
        answer.errors.add :base, "#{name}#{I18n.t('errors.messages.blank')}"
      end
    end

    if input_confirm == "enabled"
      if data.present? && data.value.present? && data.value != data.confirm
        answer.errors.add :base, "#{name}#{I18n.t('errors.messages.input_confirm_not_match')}"
      end
    end

    case input_type
    when "email_field"
      if data.present? && data.value.present?
        unless data.value =~ Cms::Member::EMAIL_REGEX
          answer.errors.add :base, "#{name}#{I18n.t('errors.messages.email')}"
        end
      end
    when "radio_button", "select"
      if data.present? && data.value.present?
        unless select_options.include?(data.value)
          answer.errors.add :base, "#{name}#{I18n.t('errors.messages.invalid')}"
        end
      end
    when "check_box"
      if data.present? && data.values.present?
        if (data.values.select(&:present?) - select_options).present?
          answer.errors.add :base, "#{name}#{I18n.t('errors.messages.invalid')}"
        end
      end
    end
  end
end
