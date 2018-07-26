class ::Opendata::Harvest::Importer::CategorySetting
  include SS::Document
  include SS::Reference::User
  include SS::Reference::Site
  include Cms::SitePermission
  include ActiveSupport::NumberHelper

  belongs_to :importer, class_name: 'Opendata::Harvest::Importer'

  set_permission_name "other_opendata_harvests", :edit

  belongs_to :category, class_name: 'Opendata::Node::Category'
  field :conditions, type: Array, default: []
  field :order, type: Integer, default: 0

  attr_accessor :in_file

  permit_params :category_id, :order, :in_file
  permit_params conditions: [:type, :value, :operator]

  seqid :id

  validates :category_id, presence: true
  validate :validate_conditions

  default_scope ->{ order_by order: 1 }

  def order
    value = self[:order].to_i
    value < 0 ? 0 : value
  end

  private

  def validate_conditions
    type_keys = I18n.t("opendata.type_condition_options").keys.map(&:to_s)
    operator_keys = I18n.t("opendata.operator_condition_options").keys.map(&:to_s)

    self.conditions = conditions.select { |cond| cond["value"].present? }.uniq
    self.conditions.each do |cond|

      if !type_keys.include?(cond["type"])
        errors.add :base, "タイプが不正です。"
      end
      if !operator_keys.include?(cond["operator"])
        errors.add :base, "操作が不正です。"
      end

      begin
        ::Regexp.new(cond["value"]) if cond["type"] == "regexp"
      rescue => e
        errors.add :base, "正規表現が不正です。 #{e.message}"
      end
    end
    errors.add :conditions, :empty if conditions.blank?
  end

  public

  def name
    name = ""
    name = "#{category.name} (#{category.filename})" if category
    name
  end

  def type_condition_options
    I18n.t("opendata.type_condition_options").map { |k, v| [v, k] }
  end

  def operator_condition_options
    I18n.t("opendata.operator_condition_options").map { |k, v| [v, k] }
  end

  def match?(imported_item)
    text_index = imported_item.harvest_text_index
    ckan_groups = imported_item.harvest_ckan_groups
    ckan_tags = imported_item.harvest_ckan_tags
    shirasagi_categories = imported_item.harvest_shirasagi_categories
    shirasagi_areas = imported_item.harvest_shirasagi_areas

    conditions.each do |cond|
      if cond["type"] == "string" && cond["operator"] == "match"

        return false if !text_index.include?(cond["value"])

      elsif cond["type"] == "string" && cond["operator"] == "unmatch"

        return false if text_index.include?(cond["value"])

      elsif cond["type"] == "regexp" && cond["operator"] == "match"

        return false if !text_index.match(::Regexp.new(cond["value"]))

      elsif cond["type"] == "regexp" && cond["operator"] == "unmatch"

        return false if text_index.match(::Regexp.new(cond["value"]))

      elsif cond["type"] == "ckan_group" && cond["operator"] == "match"

        return false if !ckan_groups.include?(cond["value"])

      elsif cond["type"] == "ckan_group" && cond["operator"] == "unmatch"

        return false if ckan_groups.include?(cond["value"])

      elsif cond["type"] == "ckan_tag" && cond["operator"] == "match"

        return false if !ckan_tags.include?(cond["value"])

      elsif cond["type"] == "ckan_tag" && cond["operator"] == "unmatch"

        return false if ckan_tags.include?(cond["value"])

      elsif cond["type"] == "shirasagi_category" && cond["operator"] == "unmatch"

        return false if shirasagi_categories.include?(cond["value"])

      elsif cond["type"] == "shirasagi_category" && cond["operator"] == "match"

        return false if !shirasagi_categories.include?(cond["value"])

      elsif cond["type"] == "shirasagi_area" && cond["operator"] == "unmatch"

        return false if shirasagi_areas.include?(cond["value"])

      elsif cond["type"] == "shirasagi_area" && cond["operator"] == "match"

        return false if !shirasagi_areas.include?(cond["value"])

      end
    end
    true
  end

  def import
    begin
      if in_file.blank? || ::File.extname(in_file.original_filename) != ".csv"
        raise I18n.t("errors.messages.invalid_csv")
      end
      table = CSV.read(in_file.path, headers: true, encoding: 'SJIS:UTF-8')
    rescue => e
      errors.add :base, e.to_s
      return
    end

    items = []
    id_given_items = {}
    table.each_with_index do |row, idx|
      id = row["#{t(:id)}"].to_s.strip
      order = row["#{t(:order)}"].to_s.strip
      category_name = row["#{t(:category_name)}"].to_s.strip
      category_filename = row["#{t(:category_filename)}"].to_s.strip

      type = row["#{t(:type)}"].to_s.strip
      value = row["#{t(:value)}"].to_s.strip
      operator = row["#{t(:operator)}"].to_s.strip

      type = I18n.t("opendata.type_condition_options").invert[type].to_s
      operator = I18n.t("opendata.operator_condition_options").invert[operator].to_s

      category = Opendata::Node::Category.site(cur_site).where(
        name: category_name,
        filename: category_filename
      ).first

      if id.present?
        item, old_idx = id_given_items[id]
        item ||= self.class.new
        item.cur_site = cur_site
        item.cur_user = cur_user
        item.category = category
        item.importer = importer
        item.order = order
        item.conditions = item.conditions + [{"type" => type, "value" => value, "operator" => operator}]
        id_given_items[id] = [item, old_idx.to_a + [idx]]
      else
        item = self.class.new
        item.cur_site = cur_site
        item.cur_user = cur_user
        item.category = category
        item.importer = importer
        item.order = order
        item.conditions = [{"type" => type, "value" => value, "operator" => operator}]
        items << [item, idx]
      end
    end

    items.each do |item, idx|
      next if item.valid?
      errors.add :base, "#{idx + 2} : #{item.errors.full_messages.join(", ")}"
    end

    id_given_items.values.each do |item, idx|
      next if item.valid?
      errors.add :base, "#{idx.map { |i| i + 2 }.join(", ")} : #{item.errors.full_messages.join(", ")}"
    end

    return false if errors.present?

    self.class.where(importer_id: importer.id).destroy_all
    items.each { |item, idx| item.save! }
    id_given_items.values.each { |item, idx| item.save! }
    true
  end

  class << self
    def to_csv
      CSV.generate do |data|
        data << %w(id order category_name category_filename type value operator).map { |k| t(k) }
        criteria.each do |item|
          item.conditions.each do |cond|
            line = []
            line << item.id
            line << item.order
            line << item.category.name
            line << item.category.filename
            line << I18n.t("opendata.type_condition_options.#{cond["type"]}")
            line << cond["value"]
            line << I18n.t("opendata.operator_condition_options.#{cond["operator"]}")
            data << line
          end
        end
      end
    end
  end
end
