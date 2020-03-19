class Cms::Column::Value::UrlField2 < Cms::Column::Value::Base
  field :html_tag, type: String
  field :html_additional_attr, type: String, default: ''
  field :link_url, type: String
  field :link_label, type: String
  field :link_target, type: String
  field :link_item_type, type: String
  field :link_item_id, type: Object

  permit_values :link_url, :link_label, :link_target

  validate :validate_link_url

  before_validation :set_link_item, unless: ->{ @new_clone }

  liquidize do
    export :effective_link_url, as: :link_url
    export :effective_link_label, as: :link_label
    export :link_target
  end

  def html_additional_attr_to_h
    attrs = {}

    if html_additional_attr.present?
      attrs = html_additional_attr.scan(/\S+?=".+?"/m).
        map { |s| s.split(/=/).size == 2 ? s.delete('"').split(/=/) : nil }.
        compact.to_h
    end

    if link_target.present?
      attrs[:target] = link_target
    end

    attrs
  end

  def effective_link_url
    link_url.presence || link_item.try(:url)
  end

  def effective_link_label
    link_label.presence || link_item.try(:name)
  end

  def import_csv(values)
    super

    values.map do |name, value|
      case name
      when self.class.t(:link_url)
        self.link_url = value
      when self.class.t(:link_label)
        self.link_label = value
      end
    end
  end

  private

  def validate_link_url
    return if link_url.blank?
    Addressable::URI.parse(link_url)
  rescue
    errors.add :link_url, :invalid
  end

  def set_link_item
    u = Addressable::URI.parse(link_url) rescue nil
    site = _parent.site || _parent.instance_variable_get(:@cur_site)

    if link_url.blank? || u.nil? || site.nil?
      self.link_item_type = nil
      self.link_item_id = nil
      remove_instance_variable :@link_item if defined? @link_item
      return
    end

    if u.relative?
      node = _parent.parent
      base_url = node ? node.full_url : site.full_url
      u = URI.join(base_url, encoded_link_url)
    end

    searches = [ "#{u.host}:#{u.port}" ]
    if u.port.nil? || u.port == 80 || u.port == 443
      searches << u.host
    end

    if site.domains.any? { |domain| searches.include?(domain) }
      # internal link
      filename = u.path[1..-1].to_s
      content = Cms::Page.site(site).where(filename: filename).first
      content ||= Cms::Node.site(site).where(filename: filename.sub(/\/$/, "")).first
      if content.present?
        self.link_item_type = content.collection_name.to_s
        self.link_item_id = content.id
        remove_instance_variable :@link_item if defined? @link_item
        return
      end
    end

    # external link
    self.link_item_type = nil
    self.link_item_id = nil
    remove_instance_variable :@link_item if defined? @link_item
  end

  def link_item
    return if link_item_type.blank? || link_item_id.blank?
    return @link_item if defined? @link_item

    @link_item ||= begin
      site = _parent.site || _parent.instance_variable_get(:@cur_site)

      case link_item_type
      when "cms_pages"
        Cms::Page.site(site).where(id: link_item_id).first.try(:becomes_with_route)
      when "cms_nodes"
        Cms::Node.site(site).where(id: link_item_id).first.try(:becomes_with_route)
      end
    end
  end

  def validate_value
    return if column.blank?

    if column.required? && effective_link_url.blank?
      self.errors.add(:link_url, :blank)
    end

    if link_label.present? && column.label_max_length.present? && column.label_max_length > 0
      if link_label.length > column.label_max_length
        self.errors.add(:link_label, :too_long, count: column.label_max_length)
      end
    end

    if link_url.present? && column.link_max_length.present? && column.link_max_length > 0
      if link_url.length > column.link_max_length
        self.errors.add(:link_url, :too_long, count: column.link_max_length)
      end
    end
  end

  def copy_column_settings
    super

    return if column.blank?

    self.html_tag = column.html_tag
    self.html_additional_attr = column.html_additional_attr
  end

  def to_default_html
    return '' if effective_link_url.blank?

    options = html_additional_attr_to_h
    ApplicationController.helpers.link_to(effective_link_label.presence || effective_link_url, effective_link_url, options)
  end
end
