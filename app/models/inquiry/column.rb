class Inquiry::Column
  include SS::Document
  include SS::Reference::Site
  include Cms::SitePermission
  include Inquiry::Addon::InputSetting

  INPUT_TYPE_VALIDATION_HANDLERS = [
    [ :email_field, :validate_email_field ].freeze,
    [ :radio_button, :validate_radio_button ].freeze,
    [ :select, :validate_select ].freeze,
    [ :check_box, :validate_check_box ].freeze,
  ].freeze

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
    node.answers.search(opts).
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

    handler = INPUT_TYPE_VALIDATION_HANDLERS.find { |type, handler| type == input_type.to_sym }
    return if handler.nil? || !respond_to?(handler[1])
    send(handler[1], answer, data)
  end

  def validate_email_field(answer, data)
    if data.present? && data.value.present?
      unless data.value =~ Cms::Member::EMAIL_REGEX
        answer.errors.add :base, "#{name}#{I18n.t('errors.messages.email')}"
      end
    end
  end

  def validate_radio_button(answer, data)
    if data.present? && data.value.present?
      unless select_options.include?(data.value)
        answer.errors.add :base, "#{name}#{I18n.t('errors.messages.invalid')}"
      end
    end
  end
  alias validate_select validate_radio_button

  def validate_check_box(answer, data)
    if data.present? && data.values.present?
      if (data.values.select(&:present?) - select_options).present?
        answer.errors.add :base, "#{name}#{I18n.t('errors.messages.invalid')}"
      end
    end
  end
end
