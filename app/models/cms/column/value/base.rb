class Cms::Column::Value::Base
  extend SS::Translation
  include SS::Document
  include SS::Liquidization

  class_attribute :_permit_values, instance_accessor: false
  self._permit_values = []

  attr_reader :in_wrap

  embedded_in :page, inverse_of: :column_values
  belongs_to :column, class_name: 'Cms::Column::Base'
  field :name, type: String
  field :order, type: Integer
  field :class_name, type: String

  after_initialize :copy_column_settings, if: ->{ new_record? }

  validate :validate_value

  liquidize do
    export :name
    export as: :html do |context|
      self.to_html(preview: context.registers[:preview])
    end
    export as: :to_s do |context|
      self.to_html(preview: context.registers[:preview])
    end
    export as: :type do
      self.class.name
    end
  end

  def self.permit_values(*fields)
    self._permit_values += Array.wrap(fields)
  end

  def to_html(options = {})
    html = _to_html(options)
    if options[:preview]
      data_attrs = [
        [ "page-id", _parent.id ], [ "column-id", id ], [ "column-name", ::CGI.escapeHTML(name) ],
        [ "column-order", order ]
      ]
      wrap = "<div class=\"ss-preview-column\" #{data_attrs.map { |k, v| "data-#{k}=\"#{v}\"" }.join(" ")}>"
      wrap += html if html
      wrap += "</div>"

      html = wrap
    end

    html || ""
  end

  def all_file_ids
    # it should be overrided by subclass to provide all attached file ids.
    []
  end

  def new_clone
    ret = self.class.new self.attributes.to_h.except('_id', '_type', 'created', 'updated')
    ret.instance_variable_set(:@new_clone, true)
    ret
  end

  def generate_public_files
  end

  def remove_public_files
  end

  def in_wrap=(value)
    self.attributes = @in_wrap = ActionController::Parameters.new(Hash(value)).permit(self.class._permit_values)
  end

  private

  def _to_html(options = {})
    if column.blank?
      return to_default_html
    end

    layout = column.layout
    if layout.blank?
      return to_default_html
    end

    render_opts = { "value" => self }

    template = Liquid::Template.parse(layout)
    template.render(render_opts).html_safe
  end

  def validate_value
    return if column.blank?

    if column.required? && value.blank?
      if self._parent
        self._parent.errors.add(:base, name + I18n.t('errors.messages.blank'))
      else
        self.errors.add(:value, :blank)
      end
    end
  end

  def copy_column_settings
    if column.present?
      self.name ||= column.name
      self.order ||= column.order
    end
  end

  def to_default_html
    ApplicationController.helpers.sanitize(self.value)
  end
end
