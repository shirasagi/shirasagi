class Inquiry::Column
  include SS::Document
  include SS::Reference::Site
  include Cms::SitePermission
  include Inquiry::Addon::InputSetting
  include Inquiry::Addon::KintoneApp::Column
  include Inquiry::Addon::ExpandColumn
  include SS::PluginRepository

  plugin_class Inquiry::Plugin
  plugin_type 'column'

  INPUT_TYPE_VALIDATION_HANDLERS = [
    [ :email_field, :validate_email_field ].freeze,
    [ :number_field, :validate_number_field ].freeze,
    [ :date_field, :validate_date_field ].freeze,
    [ :datetime_field, :validate_datetime_field ].freeze,
    [ :radio_button, :validate_radio_button ].freeze,
    [ :select, :validate_select ].freeze,
    [ :check_box, :validate_check_box ].freeze,
    [ :upload_file, :validate_upload_file ].freeze,
  ].freeze

  set_permission_name "other_inquiry_columns"

  seqid :id
  belongs_to :node, class_name: "Inquiry::Node::Form"
  field :state, type: String, default: "public"
  field :name, type: String
  field :html, type: String, default: ""
  field :order, type: Integer, default: 0
  field :max_upload_file_size, type: Integer, default: 0, overwrite: true
  field :branch_section_ids, type: Array, default: []

  permit_params :id, :node_id, :state, :name, :html, :order, :max_upload_file_size,
    branch_section_ids: []

  validates :node_id, :state, :name, :max_upload_file_size, presence: true

  def answer_data(opts = {})
    answers = node.answers
    answers = answers.site(opts[:site]) if opts[:site].present?
    answers = answers.allow(:read, opts[:user]) if opts[:user].present?
    answers.search(opts).
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

  def branch_section_options
    form.columns.where(input_type: 'section').order_by(order: 1).map do |c|
      [I18n.t('gws/column.show_section', name: c.name), c.id]
    end
  end

  def branch_section_id(index)
    return 'none' if branch_section_ids[index] == ''
    return branch_section_ids[index] if branch_section_ids[index]
    nil
  end

  def validate_data(answer, data, in_reply)
    return if input_type == 'section'

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

  def validate_number_field(answer, data)
    if data.blank? || data.value.blank?
      unless data.value.numeric?
        answer.errors.add :base, "#{name}#{I18n.t('errors.messages.not_a_number')}"
      end
    end
  end

  def validate_date_field(answer, data)
    return if data.blank? || data.value.blank?
    begin
      DateTime.iso8601(data.value)
      data.values.map do |value|
        DateTime.iso8601(value)
      end
    rescue => e
      answer.errors.add :base, "#{name}#{I18n.t('errors.messages.not_a_date')}"
    end
  end

  def validate_datetime_field(answer, data)
    return if data.blank? || data.value.blank?
    begin
      DateTime.iso8601(data.value)
      data.values.map do |value|
        DateTime.iso8601(value)
      end
    rescue => e
      answer.errors.add :base, "#{name}#{I18n.t('errors.messages.not_a_datetime')}"
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
    # MegaBytes >> Bytes
    if self.max_upload_file_size.to_i > 0
      file_size  = data.values[3].to_i
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
