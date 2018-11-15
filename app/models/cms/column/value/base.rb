class Cms::Column::Value::Base
  extend SS::Translation
  include SS::Document
  include SS::Liquidization

  LINK_CHECK_EXCLUSION_FIELDS = %w(_id created updated deleted text_index column_id name order class_name _type file_id).freeze

  class_attribute :_permit_values, instance_accessor: false
  self._permit_values = []

  attr_reader :in_wrap, :link_errors

  embedded_in :page, inverse_of: :column_values
  belongs_to :column, class_name: 'Cms::Column::Base'
  field :name, type: String
  field :order, type: Integer
  field :class_name, type: String
  field :alignment, type: String

  after_initialize :copy_column_settings, if: ->{ new_record? }

  validate :validate_value

  validate :validate_link_check, on: :link

  liquidize do
    export :name
    export :alignment
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

    wrap_data = []
    wrap_css_classes = []

    if options[:preview]
      wrap_data += [
        [ "page-id", _parent.id ], [ "column-id", id ], [ "column-name", ::CGI.escapeHTML(name) ],
        [ "column-order", order ]
      ]
      wrap_css_classes << "ss-preview-column"
    end

    if self._parent.form.sub_type_entry?
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

  def new_clone
    ret = self.class.new self.attributes.to_h.except('_type')
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
      self.errors.add(:value, :blank)
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

  def validate_link_check
    @link_errors = []
    check = {}
    fields.each_key do |key|
      next if LINK_CHECK_EXCLUSION_FIELDS.include?(key)
      val = send(key)
      next unless val.is_a?(String)
      next if val.blank?
      find_url(val).each do |url|
        next if url[0] == '#'
        if url[0] == "/"
          str = column.form.site.https == "enabled" ? "https://" : "http://"
          str += column.form.site.domains_with_subdir[0]
          url = str + url
        end

        next if check.key?(url)
        check[url] = true

        result = check_url(url)
        @link_errors << [url, result]
      end
    end
  end

  def find_url(val)
    val.scan(%r!<a href="(.+?)">.+?</a>!).flatten | URI.extract(val, %w(http https))
  end

  def check_url(url)
    proxy = ( url =~ /^https/ ) ? ENV['HTTPS_PROXY'] : ENV['HTTP_PROXY']
    progress_data_size = nil
    opts = {
      proxy: proxy,
      progress_proc: ->(size) do
        progress_data_size = size
        raise "200"
      end
    }

    begin
      Timeout.timeout(2) do
        URI.open(url, opts) { |f| return f.status[0].to_i }
      end

      :success
    rescue Timeout::Error
      return :failure
    rescue => e
      return :success if progress_data_size
    end

    :failure
  end
end
