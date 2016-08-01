require 'open-uri'

class Opendata::Facility::AssocJob < Cms::ApplicationJob
  def perform(facility_site_id, facility_node_id, forcibly_updates)
    return unless self.site.dataset_enabled?
    @dataset_node = Opendata::Node::Dataset.site(self.site).first
    return if @dataset_node.blank?

    @facility_site = Cms::Site.find(facility_site_id)
    @facility_node = Cms::Node.site(@facility_site).find(facility_node_id).becomes_with_route
    @forcibly_updates = forcibly_updates

    import_csv_as_resource

    Rails.logger.info("imported #{@facility_node.name} from #{@facility_site.name}")
  end

  private
    def import_csv_as_resource
      find_or_create_dataset
      return if !@forcibly_updates && @dataset.resources.present?

      download_csv
      clear_resources
      add_resource
      save_dataset
      close_csv_file
    end

    def download_csv
      open("#{@facility_node.full_url}index.csv") do |f|
        f.binmode

        @csv_file = Fs::UploadedFile.new("opendata")
        @csv_file.binmode
        @csv_file.write(f.read)
        @csv_file.rewind
        @csv_file.original_filename = "#{@facility_node.filename.tr('/', '_')}.csv"
        @csv_file.content_type = f.content_type
      end
    end

    def close_csv_file
      @csv_file.close if @csv_file
    end

    def find_or_create_dataset
      @dataset = Opendata::Dataset.site(self.site).node(@dataset_node).and_associated(@facility_node).first
      @dataset ||= begin
        dataset = Opendata::Dataset.create(
          cur_site: self.site,
          cur_node: @dataset_node,
          name: @facility_node.name,
          text: I18n.t("opendata.assoc_job.dataset_text", name: @facility_node.name, url: @facility_node.full_url),
          category_ids: find_category_ids,
          group_ids: @dataset_node.group_ids,
          assoc_site_id: @facility_site.id,
          assoc_node_id: @facility_node.id,
          state: 'closed')
        Rails.logger.info("created node: #{dataset.name}")
        dataset
      end
    end

    def clear_resources
      @dataset.resources.destroy_all
    end

    def add_resource
      resource = @dataset.resources.new
      resource.name = @facility_node.name
      resource.text = I18n.t("opendata.assoc_job.resource_text",
                             name: @facility_node.name, now: I18n.l(Time.zone.now, format: :long))
      resource.license_id = find_license.id
      resource.in_file = @csv_file
      resource.save!
      resource
    end

    def find_category_ids
      categories = Opendata::Node::Category.site(self.site).node(@dataset_node.default_st_categories.first).and_public
      categories.pluck(:id)
    end

    def find_license
      Opendata::License.site(self.site).and_public.order_by(order: 1, id: 1).first
    end

    def save_dataset
      @dataset.save!
    end
end
