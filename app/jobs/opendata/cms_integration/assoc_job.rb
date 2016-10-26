class Opendata::CmsIntegration::AssocJob < Cms::ApplicationJob
  def perform(site_id, node_id, page_id, action)
    return unless self.site.dataset_enabled?
    @dataset_node = Opendata::Node::Dataset.site(self.site).first
    return if @dataset_node.blank?

    @cms_site = Cms::Site.find(site_id)
    @cms_node = Cms::Node.site(@cms_site).find(node_id).becomes_with_route
    @cur_page = Cms::Page.site(@cms_site).node(@cms_node).find(page_id).becomes_with_route

    @file_goes_to = []

    action = action.to_sym
    if action == :create_or_update
      if @cur_page.opendata_dataset_state.present? && @cur_page.opendata_dataset_state != 'none'
        create_or_update_associated_dataset
      else
        close_associated_dataset
      end
    elsif action == :destroy
      close_associated_dataset
    end

    true
  end

  private
    def close_associated_dataset
      Opendata::Dataset.site(self.site).node(@dataset_node).and_resource_associated_page(@cur_page).each do |dataset|
        dataset.resources.and_associated_page(@cur_page).each do |resource|
          if resource.assoc_method != 'auto'
            Rails.logger.info("#{resource.name}: auto association is disabled in #{dataset.name}")
            next
          end

          resource.destroy
          Rails.logger.info("#{resource.name}: resource is destroyed")
        end
        dataset.save!
      end

      dataset = Opendata::Dataset.site(self.site).node(@dataset_node).and_associated_page(@cur_page).first
      # page isn't associated with dataset
      return if dataset.blank?
      # dataset is alread closed
      return if dataset.state == 'closed'
      # auto association is disabled
      if dataset.assoc_method != 'auto'
        Rails.logger.info("#{dataset.name}: auto association is disabled")
        return
      end

      dataset.state = 'closed'
      dataset.save!
      Rails.logger.info("#{dataset.name}: dataset is closed")
    end

    def create_or_update_associated_dataset
      page_html = get_page_html
      if page_html.blank?
        Rails.logger.warn("#{@cur_page.name}: html is blank")
        return
      end
      if @cur_page.files.blank?
        Rails.logger.warn("#{@cur_page.name}: no files are attached")
        return
      end

      dataset = get_associated_dataset
      # auto association is disabled
      if dataset.present?
        if dataset.assoc_method == 'auto'
          update_dataset_by_page(dataset)
        else
          Rails.logger.info("#{dataset.name}: auto association is disabled")
        end
      end

      @cur_page.files.each do |file|
        state = @cur_page.opendata_resources_state(file)
        case state
        when 'none'
          # nothing to do with this file
          next
        when 'same'
          dataset ||= create_associated_dataset
          create_or_update_resource(dataset, file)
        when 'existance'
          ds = @cur_page.opendata_resources_datasets(file).site(self.site).first
          if ds.present?
            create_or_update_resource(ds, file)
          end
        end
      end

      destroy_all_resources_unassociated_with_page
    end

    def get_page_html
      if @cur_page.body_layout.present?
        @page_html ||= @cur_page.body_parts.join
      else
        @page_html ||= @cur_page.html
      end
    end

    def get_associated_dataset
      dataset = @cur_page.opendata_datasets.site(self.site).first if @cur_page.opendata_dataset_state == 'existance'
      dataset ||= Opendata::Dataset.site(self.site).node(@dataset_node).and_associated_page(@cur_page).first
      dataset
    end

    def create_associated_dataset
      attributes = {
        cur_site: self.site,
        cur_node: @dataset_node,
        name: @cur_page.name,
        text: convert_to_text(get_page_html),
        category_ids: find_category_ids(@cur_page),
        area_ids: find_area_ids(@cur_page),
        dataset_group_ids: find_dataset_group_ids(@cur_page),
        group_ids: @dataset_node.group_ids,
        assoc_site_id: @cms_site.id,
        assoc_node_id: @cms_node.id,
        assoc_page_id: @cur_page.id,
        state: @cur_page.opendata_dataset_state.presence == 'public' ? 'public' : 'closed' }
      attributes[:contact_charge] = @cur_page.contact_charge if @cur_page.respond_to?(:contact_charge)
      attributes[:contact_email] = @cur_page.contact_email if @cur_page.respond_to?(:contact_email)
      attributes[:contact_fax] = @cur_page.contact_fax if @cur_page.respond_to?(:contact_fax)
      attributes[:contact_group_id] = @cur_page.contact_group_id if @cur_page.respond_to?(:contact_group_id)
      attributes[:contact_state] = @cur_page.contact_state if @cur_page.respond_to?(:contact_state)
      attributes[:contact_tel] = @cur_page.contact_tel if @cur_page.respond_to?(:contact_tel)

      dataset = Opendata::Dataset.create(attributes)
      Rails.logger.info("#{dataset.name}: dataset is created")
      dataset
    end

    def update_dataset_by_page(dataset)
      dataset.name = @cur_page.name
      dataset.text = convert_to_text(get_page_html)
      dataset.category_ids = find_category_ids(@cur_page)
      dataset.area_ids = find_area_ids(@cur_page)
      dataset.dataset_group_ids = find_dataset_group_ids(@cur_page)
      dataset.assoc_site_id = @cms_site.id
      dataset.assoc_node_id = @cms_node.id
      dataset.assoc_page_id = @cur_page.id
      dataset.touch
      dataset.save!
    end

    def create_or_update_resource(dataset, file)
      resources = dataset.resources.and_associated_file(file)
      if resources.blank?
        # create new resource
        create_resource(dataset, file)
      else
        # update resource
        update_resources(dataset, resources, file)
      end
    end

    def create_resource(dataset, file)
      license_id = find_license(file).id

      resource = dataset.resources.new
      resource.associate_resource_with_file!(@cur_page, file, license_id)

      @file_goes_to << [ file.filename, dataset.id, resource.id ]
      Rails.logger.info("#{file.name}: resource is created in #{dataset.name}")
    end

    def update_resources(dataset, resources, file)
      license_id = find_license(file).id

      resources.each do |resource|
        if resource.assoc_method != 'auto'
          Rails.logger.info("#{resource.name}: auto association is disabled in #{dataset.name}")
          next
        end

        resource.update_resource_with_file!(@cur_page, file, license_id)

        @file_goes_to << [ file.filename, dataset.id, resource.id ]
        Rails.logger.info("#{file.name}: resource is updated in #{dataset.name}")
      end
    end

    def destroy_all_resources_unassociated_with_page
      Opendata::Dataset.site(self.site).node(@dataset_node).and_resource_associated_page(@cur_page).each do |dataset|
        dataset.resources.and_associated_page(@cur_page).each do |resource|
          if resource.assoc_method != 'auto'
            Rails.logger.info("#{resource.name}: auto association is disabled in #{dataset.name}")
            next
          end

          unless resource_is_updated?(dataset, resource)
            resource.destroy
            Rails.logger.info("#{resource.name}: resource is destroyed")
            next
          end
        end

        dataset.save!
      end
    end

    def resource_is_updated?(dataset, resource)
      filename = resource.assoc_filename
      @file_goes_to.find do |fname, ds_id, rs_id|
        fname == filename && ds_id == dataset.id && rs_id == resource.id
      end
    end

    def find_category_ids(page)
      page.opendata_categories.site(self.site).and_public.pluck(:id)
    end

    def find_area_ids(page)
      page.opendata_areas.site(self.site).and_public.pluck(:id)
    end

    def find_dataset_group_ids(page)
      page.opendata_dataset_groups.site(self.site).and_public.pluck(:id)
    end

    def find_license(file)
      license = @cur_page.opendata_resources_licenses(file).site(self.site).and_public.order_by(order: 1, id: 1).first
      license ||= @cur_page.opendata_licenses.site(self.site).and_public.order_by(order: 1, id: 1).first
      criteria = Opendata::License.site(self.site).and_public
      license ||= criteria.and_default.order_by(order: 1, id: 1).first
      license ||= criteria.order_by(order: 1, id: 1).first
      license
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
