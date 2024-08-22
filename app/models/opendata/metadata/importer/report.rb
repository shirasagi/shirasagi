class Opendata::Metadata::Importer
  class Report
    include SS::Document
    include SS::Reference::Site
    include Cms::SitePermission
    include ActiveSupport::NumberHelper

    set_permission_name "opendata_datasets"

    belongs_to :importer, class_name: 'Opendata::Metadata::Importer'
    has_many :datasets, class_name: 'Opendata::Metadata::Importer::ReportDataset', dependent: :destroy, inverse_of: :report

    field :notice_subject, type: String
    field :notice_body, type: String

    default_scope ->{ order_by created: -1 }

    def name
      created.try { |time| I18n.l(time, format: :picker) }
    end

    def new_dataset
      report_dataset = Opendata::Metadata::Importer::ReportDataset.new
      report_dataset.report = self
      report_dataset
    end

    def to_csv
      I18n.with_locale(I18n.default_locale) do
        CSV.generate do |data|
          data << %w(
            dataset_no
            dataset_name
            category_ids
            estat_category_ids
            area_ids
          ).map { |k| t(k) }

          no = 0
          datasets.each_with_index do |dataset, d_idx|
            line = []
            line << d_idx + 1
            line << dataset.name
            line << dataset.categories.pluck(:name).join("\n")
            line << dataset.estat_categories.pluck(:name).join("\n")
            line << dataset.areas.pluck(:name).join("\n")
            data << line

            no += 1
          end
        end
      end
    end
  end

  class ReportDataset
    include SS::Document

    belongs_to :report, class_name: 'Opendata::Metadata::Importer::Report'
    embeds_many :resources, class_name: 'Opendata::Metadata::Importer::ReportResource'

    field :order, type: Integer
    field :url, type: String
    field :name, type: String

    embeds_ids :categories, class_name: "Opendata::Node::Category"
    embeds_ids :estat_categories, class_name: "Opendata::Node::EstatCategory"
    embeds_ids :areas, class_name: "Opendata::Node::Area"

    field :uuid, type: String
    field :imported_attributes, type: Hash
    field :state, type: String, default: "successed"
    field :error_messages, type: Array, default: []

    default_scope ->{ order_by order: 1 }

    def imported_dataset
      @_imported_dataset ||= Opendata::Dataset.where(uuid: uuid).first
    end

    def set_reports(dataset, attributes, url, order)
      self.order = order
      self.url = url
      self.name = dataset.name
      self.category_ids = dataset.category_ids
      self.estat_category_ids = dataset.estat_category_ids
      self.area_ids = dataset.area_ids
      self.uuid = dataset.uuid

      self.imported_attributes = attributes
    end

    def new_resource
      report_resource = ::Opendata::Metadata::Importer::ReportResource.new
      report_resource.dataset = self
      report_resource
    end

    def add_error(message)
      self.state = "failed"
      self.error_messages << message
    end

    class << self
      def search(params = {})
        criteria = self.where({})
        return criteria if params.blank?

        category_ids = params[:category_ids].to_a.select(&:present?).map(&:to_i)
        estat_category_ids = params[:estat_category_ids].to_a.select(&:present?).map(&:to_i)
        area_ids = params[:area_ids].to_a.select(&:present?).map(&:to_i)

        if params[:keyword].present?
          criteria = criteria.keyword_in params[:keyword], :name
        end
        if category_ids.present?
          criteria = criteria.in(category_ids: category_ids)
        end
        if estat_category_ids.present?
          criteria = criteria.in(estat_category_ids: estat_category_ids)
        end
        if area_ids.present?
          criteria = criteria.in(area_ids: area_ids)
        end

        criteria
      end
    end
  end

  class ReportResource
    include SS::Document

    embedded_in :dataset, class_name: 'Opendata::Metadata::Importer::ReportDataset', inverse_of: :resources

    field :order, type: Integer
    field :url, type: String
    field :filename, type: String
    field :name, type: String
    field :format, type: String
    field :size, type: Integer, default: 0

    field :uuid, type: String
    field :revision_id, type: String

    field :imported_attributes, type: Hash

    field :state, type: String, default: "successed"
    field :error_messages, type: Array, default: []

    default_scope ->{ order_by order: 1 }

    def set_reports(resource, attributes, order)
      self.order = order
      self.url = attributes["url"]
      self.filename = resource.filename
      self.name = resource.name
      self.format = resource.format

      if resource.source_url.present?
        self.size = 0
      else
        self.size = resource.file.size
      end

      self.imported_attributes = attributes
      self.uuid = resource.uuid
      self.revision_id = resource.revision_id
    end

    def add_error(message)
      self.state = "failed"
      self.error_messages << message
    end
  end
end
