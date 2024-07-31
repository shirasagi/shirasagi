class Cms::Column::Value::Base
  extend SS::Translation
  include SS::Document
  include SS::Liquidization

  LINK_CHECK_EXCLUSION_FIELDS = %w(_id created updated deleted text_index column_id name order class_name _type file_id).freeze

  class_attribute :_permit_values, instance_accessor: false
  self._permit_values = []

  define_model_callbacks :parent_save
  define_model_callbacks :parent_create
  define_model_callbacks :parent_update
  define_model_callbacks :parent_destroy

  attr_accessor :cur_user, :cur_site, :link_check_user
  attr_reader :in_wrap, :link_errors, :origin_id

  embedded_in :page, inverse_of: :column_values
  belongs_to :column, class_name: 'Cms::Column::Base'
  field :name, type: String
  field :order, type: Integer
  field :alignment, type: String

  before_validation :copy_column_settings
  validate :validate_value
  validate :validate_link_check, on: :link

  liquidize do
    export :name
    export :alignment
    export as: :html do |context|
      render_html_for_liquid(context)
    end
    export as: :to_s do |context|
      render_html_for_liquid(context)
    end
    export as: :type do
      self.class.name
    end
  end

  def self.permit_values(*fields)
    self._permit_values += Array.wrap(fields)
  end

  def to_html(options = {})
    return "" if column.blank?

    html = _to_html(options)

    wrap_data = []
    wrap_css_classes = []

    if options[:preview]
      wrap_data += [
        [ "page-id", _parent.id ], [ "column-id", id ], [ "column-name", ::CGI.escapeHTML(name) ],
        [ "column-order", order ]
      ]
      wrap_css_classes << "ss-preview-column"
    end

    if column.form.sub_type_entry?
      wrap_css_classes << "ss-alignment"
      wrap_css_classes << "ss-alignment-#{alignment.presence || "flow"}"
    end

    if wrap_data.present? || wrap_css_classes.present?
      attrs = []

      if wrap_data.present?
        attrs += wrap_data.map { |k, v| "data-#{k}=\"#{v}\"" }
      end
      if wrap_css_classes.present?
        attrs << "class=\"#{wrap_css_classes.join(" ")}\""
      end

      wrap = "<div #{attrs.join(" ")}>"
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

  def clone_to(to_item, opts = {})
    attrs = self.attributes.except('_id').slice(*self.class.fields.keys.map(&:to_s))
    ret = to_item.column_values.build(attrs)
    ret.instance_variable_set(:@new_clone, true)
    ret.instance_variable_set(:@origin_id, self.id)
    ret.instance_variable_set(:@merge_values, true) if opts[:merge_values]
    ret.created = ret.updated = Time.zone.now
    ret
  end

  def generate_public_files
  end

  def remove_public_files
  end

  def in_wrap=(value)
    self.attributes = @in_wrap = ActionController::Parameters.new(Hash(value)).permit(self.class._permit_values)
  end

  def import_csv(values)
    values.map do |name, value|
      case name
      when self.class.t(:alignment)
        self.alignment = value.present? ? I18n.t("cms.options.alignment").invert[value] : nil
      when self.class.t(:value)
        self.value = value
      end
    end
  end

  def history_summary
    h = []
    h << "#{t("value")}: #{value}" if try(:value).present?
    h << "#{t("alignment")}: #{I18n.t("cms.options.alignment.#{alignment}")}"
    h.join(",")
  end

  def import_csv_cell(value)
    try(:value=, value)
  end

  def export_csv_cell
    try(:value)
  end

  def search_values(values)
    return false unless values.instance_of?(Array)
    (values & [try(:value)]).present?
  end

  private

  def render_html_for_liquid(context)
    return to_default_html if @liquid_context

    @liquid_context = context
    begin
      to_html(preview: context.registers[:preview])
    ensure
      @liquid_context = nil
    end
  end

  def _to_html(options = {})
    layout = column.layout
    if layout.blank?
      return to_default_html
    end

    render_opts = { "value" => self }

    template = Liquid::Template.parse(layout)
    template.render(render_opts).html_safe
  end

  def skip_required?
    return false if validation_context.is_a?(Array) && validation_context.include?(:form_check)
    _parent.skip_required?
  end

  def validate_value
    return if column.blank? || skip_required?

    if column.required? && value.blank?
      self.errors.add(:value, :blank)
    end
  end

  def copy_column_settings
    return if self.name.present? && self.order.present?
    return if column.blank?

    self.name ||= column.name
    self.order ||= column.order
  end

  def to_default_html
    ApplicationController.helpers.sanitize(self.value)
  end

  def validate_link_check
    @link_errors = {}

    root_url = column.form.site.full_root_url
    checker = Cms::LinkChecker.new(cur_user: @link_check_user, root_url: root_url)

    fields.each_key do |key|
      next if LINK_CHECK_EXCLUSION_FIELDS.include?(key)
      val = send(key)
      next unless val.is_a?(String)
      next if val.blank?
      find_url(val).each do |url|
        next if url[0] == '#'

        if url[0] == "/"
          url = ::File.join(root_url, url)
        end

        next if @link_errors[url]
        @link_errors[url] = checker.check_url(url)
      end
    end
  end

  def find_url(val)
    val.scan(%r!<a.*?href="(.+?)">.+?</a>!).flatten | URI.extract(val, %w(http https))
  end

  class << self
    def form_example_layout
      h = []
      h << %({% if value.value %})
      h << %(  {{ value.value }})
      h << %({% endif %})
      h.join("\n")
    end

    def build_mongo_query(operator, condition_values)
      case operator
      when "any_of"
        { value: { "$in" => condition_values } }
      when "none_of"
        { value: { "$nin" => condition_values } }
      when "start_with"
        { value: { "$in" => condition_values.map { |str| /^#{::Regexp.escape(str)}/ } } }
      when "end_with"
        { value: { "$in" => condition_values.map { |str| /#{::Regexp.escape(str)}$/ } } }
      end
    end
  end
end
