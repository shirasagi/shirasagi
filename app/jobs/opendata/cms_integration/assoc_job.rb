class Opendata::CmsIntegration::AssocJob < Cms::ApplicationJob
  def perform(site_id, node_id, page_id, action)
    return unless self.site.dataset_enabled?
    @dataset_node = Opendata::Node::Dataset.site(self.site).first
    return if @dataset_node.blank?

    @cms_site = Cms::Site.find(site_id)
    @cms_node = Cms::Node.site(@cms_site).find(node_id).becomes_with_route

    @cur_page = Cms::Page.site(@cms_site).node(@cms_node).and_public.find(page_id).becomes_with_route

    if action.to_sym == :create_or_update
      if @cur_page.opendata_state_public?
        create_or_update_associated_dataset
      else
        close_associated_dataset
      end
    else
      close_associated_dataset
    end

    true
  end

  private
    def create_or_update_associated_dataset
      return if @cur_page.html.blank?
      return if @cur_page.files.blank?

      dataset = Opendata::Dataset.site(self.site).node(@dataset_node).and_associated_page(@cur_page).first
      dataset ||= create_associated_dataset
      create_or_update_resource(dataset)
      dataset
    end

    def close_associated_dataset
      dataset = Opendata::Dataset.site(self.site).node(@dataset_node).and_associated_page(@cur_page).first
      # page isn't associated with dataset
      return if dataset.blank?
      # dataset is alread closed
      return if dataset.state == 'closed'

      dataset.state = 'closed'
      dataset.save!
      Rails.logger.info("closed dataset: #{dataset.name}")
    end

    def create_associated_dataset
      attributes = {
        cur_site: self.site,
        cur_node: @dataset_node,
        name: @cur_page.name,
        text: convert_to_text(@cur_page.html),
        category_ids: find_category_ids(@cur_page),
        group_ids: @dataset_node.group_ids,
        assoc_site_id: @cms_site.id,
        assoc_node_id: @cms_node.id,
        assoc_page_id: @cur_page.id,
        state: 'closed' }
      attributes[:contact_charge] = @cur_page.contact_charge if @cur_page.respond_to?(:contact_charge)
      attributes[:contact_email] = @cur_page.contact_email if @cur_page.respond_to?(:contact_email)
      attributes[:contact_fax] = @cur_page.contact_fax if @cur_page.respond_to?(:contact_fax)
      attributes[:contact_group_id] = @cur_page.contact_group_id if @cur_page.respond_to?(:contact_group_id)
      attributes[:contact_state] = @cur_page.contact_state if @cur_page.respond_to?(:contact_state)
      attributes[:contact_tel] = @cur_page.contact_tel if @cur_page.respond_to?(:contact_tel)

      dataset = Opendata::Dataset.create(attributes)
      Rails.logger.info("created dataset: #{dataset.name}")
      dataset
    end

    def create_or_update_resource(dataset)
      # 差分更新
      resource_file_ids = dataset.resources.pluck(:assoc_file_id).uniq
      @cur_page.files.each do |file|
        if resource_file_ids.include?(file.id)
          resource_file_ids.delete(file.id)
        else
          # create resource
          Fs::UploadedFile.create_from_file(file, filename: file.filename, content_type: file.content_type) do |tmp_file|
            resource = dataset.resources.new
            resource.name = file.name.gsub(/\..*$/, '')
            resource.license_id = find_license.id
            resource.in_file = tmp_file
            resource.assoc_site_id = @cur_page.site.id
            resource.assoc_node_id = @cur_page.parent.id
            resource.assoc_page_id = @cur_page.id
            resource.assoc_file_id = file.id
            resource.save!
          end
        end
      end

      # `resource_file_ids` contain removed file ids
      resource_file_ids.each do |file_id|
        resource = dataset.resources.where(assoc_file_id: file_id).first
        resource.destroy
      end
    end

    def find_category_ids(page)
      categories = Opendata::Node::Category.site(self.site).node(@dataset_node.default_st_categories.first).and_public
      categories.pluck(:id)
    end

    def find_license
      Opendata::License.site(self.site).and_public.order_by(order: 1, id: 1).first
    end

    def convert_to_text(html)
      html = html.dup
      html.gsub!(/<br.*?>/, "\n")
      html.gsub!(/<.+?>/, '')
      html = CGI.unescapeHTML(html)
      html.gsub!(/&nbsp;/, ' ')
      html
    end
end
