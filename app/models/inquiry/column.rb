class Inquiry::Column
  include SS::Document
  include SS::Reference::Site
  include Cms::SitePermission
  include Inquiry::Addon::InputSetting
  include Cms::Addon::GroupPermission

  INPUT_TYPE_VALIDATION_HANDLERS = [
    [ :email_field, :validate_email_field ].freeze,
    [ :radio_button, :validate_radio_button ].freeze,
    [ :select, :validate_select ].freeze,
    [ :check_box, :validate_check_box ].freeze,
    [ :upload_file, :validate_upload_file ].freeze,
  ].freeze

  set_permission_name "inquiry_columns"

  seqid :id
  field :node_id, type: Integer
  field :state, type: String, default: "public"
  field :name, type: String
  field :html, type: String, default: ""
  field :order, type: Integer, default: 0
  field :max_upload_file_size, type: Integer, default: 0, overwrite: true

  belongs_to :node, foreign_key: :node_id, class_name: "Inquiry::Node::Form"

  permit_params :id, :node_id, :state, :name, :html, :order, :max_upload_file_size

  validates :node_id, :state, :name, :max_upload_file_size, presence: true

  def answer_data(opts = {})
    node.answers.search(opts).
      map { |ans| ans.data.entries.select { |data| data.column_id == id } }.flatten
  end

  def state_options
    [
      [I18n.t('ss.options.state.public'), 'public'],
      [I18n.t('ss.options.state.closed'), 'closed'],
    ]
  end

  def order
    value = self[:order].to_i
    value < 0 ? 0 : value
  end

  def validate_data(answer, data, in_reply)
    if required?(in_reply)
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
      unless Cms::Member::EMAIL_REGEX.match?(data.value)
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

  def validate_upload_file(answer, data)
    return if SS.config.cms.enable_lgwan
    # MegaBytes >> Bytes
    if self.max_upload_file_size.to_i > 0
      file_size  = data.values[2].to_i
      limit_size = (self.max_upload_file_size * 1024 * 1024).to_i

      if data.present? && data.value.present?
        if file_size > limit_size
          answer.errors.add :base, "#{name}#{I18n.t(
            "errors.messages.too_large_file",
            filename: data.values[1],
            size: ApplicationController.helpers.number_to_human_size(file_size),
            limit: ApplicationController.helpers.number_to_human_size(limit_size))}"
        end
      end
    end
  end
end
