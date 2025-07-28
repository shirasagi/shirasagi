class Opendata::Harvest::Importer
  class EstatCategorySetting
    include SS::Document
    include SS::Reference::User
    include SS::Reference::Site
    include Cms::SitePermission
    include ActiveSupport::NumberHelper

    belongs_to :importer, class_name: 'Opendata::Harvest::Importer'

    set_permission_name "other_opendata_harvests", :edit

    belongs_to :category, class_name: 'Opendata::Node::EstatCategory'
    field :conditions, type: Array, default: []
    field :order, type: Integer, default: 0

    attr_accessor :in_file

    permit_params :category_id, :order, :in_file
    permit_params conditions: [:type, :value, :operator]

    seqid :id

    validates :category_id, presence: true
    validate :validate_conditions

    private

    def validate_conditions
      type_keys = I18n.t("opendata.type_condition_options").keys.map(&:to_s)
      operator_keys = I18n.t("opendata.operator_condition_options").keys.map(&:to_s)

      self.conditions = conditions.select { |cond| cond["value"].present? }.uniq
      self.conditions.each do |cond|

        if !type_keys.include?(cond["type"])
          errors.add :base, I18n.t("opendata.errors.messages.invalid_type")
        end
        if !operator_keys.include?(cond["operator"])
          errors.add :base, I18n.t("opendata.errors.messages.invalid_operator")
        end

        begin
          ::Regexp.new(cond["value"]) if cond["type"] == "regexp"
        rescue => e
          errors.add :base, "#{I18n.t("opendata.errors.messages.invalid_regexp")} #{e.message}"
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
      shirasagi_estat_categories = imported_item.harvest_shirasagi_estat_categories
      shirasagi_areas = imported_item.harvest_shirasagi_areas

      conditions.each do |cond|
        result = case cond["type"]
                 when 'string'
                   text_index.include?(cond["value"])
                 when 'regexp'
                   text_index.match?(::Regexp.new(cond["value"]))
                 when 'ckan_group'
                   ckan_groups.include?(cond["value"])
                 when 'ckan_tag'
                   ckan_tags.include?(cond["value"])
                 when 'shirasagi_category'
                   shirasagi_categories.include?(cond["value"])
                 when 'shirasagi_estat_category'
                   shirasagi_estat_categories.include?(cond["value"])
                 when 'shirasagi_area'
                   shirasagi_areas.include?(cond["value"])
                 else
                   nil
                 end

        next if result.nil?

        case cond["operator"]
        when 'match'
          return false if !result
        when 'unmatch'
          return false if result
        end
      end
      true
    end

    def import
      if in_file.blank? || ::File.extname(in_file.original_filename).try(:downcase) != ".csv"
        errors.add :base, :invalid_csv
        return
      end
      if !SS::Csv.valid_csv?(in_file, headers: true)
        errors.add :base, :malformed_csv
        return
      end

      items = []
      id_given_items = {}
      SS::Csv.foreach_row(in_file, headers: true).each_with_index do |row, idx|
        id = row[t(:id).to_s].to_s.strip
        order = row[t(:order).to_s].to_s.strip
        category_name = row[t(:category_name).to_s].to_s.strip
        category_filename = row[t(:category_filename).to_s].to_s.strip

        type = row[t(:type).to_s].to_s.strip
        value = row[t(:value).to_s].to_s.strip
        operator = row[t(:operator).to_s].to_s.strip

        type = I18n.t("opendata.type_condition_options").invert[type].to_s
        operator = I18n.t("opendata.operator_condition_options").invert[operator].to_s

        category = Opendata::Node::EstatCategory.site(cur_site).where(
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
        SS::Model.copy_errors(item, self, prefix: "#{idx + 2} : ")
      end

      id_given_items.values.each do |item, idx|
        next if item.valid?
        SS::Model.copy_errors(item, self, prefix: "#{idx.map { |i| i + 2 }.join(", ")} : ")
      end

      return false if errors.present?

      self.class.where(importer_id: importer.id).destroy_all
      items.each { |item, idx| item.save! }
      id_given_items.values.each { |item, idx| item.save! }
      true
    end

    class << self
      def to_csv
        I18n.with_locale(I18n.default_locale) do
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
  end
end
