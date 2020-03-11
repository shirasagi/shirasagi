module Opendata::Harvest::CkanApiExporter
  extend ActiveSupport::Concern
  include Opendata::Harvest::CkanApiExportInitializer

  def put_log(message)
    Rails.logger.warn(message)
    puts message
  end

  def export
    put_log "export to #{url} (Ckan API)"

    @package = ::Opendata::Harvest::CkanPackage.new(url)
    dataset_ids = Opendata::Dataset.where(filename: /^#{::Regexp.escape(node.filename)}\//, depth: node.depth + 1).
      and_public.pluck(:id)
    put_log "datasets #{dataset_ids.size}"

    @dataset_relations = {}
    @resource_relations = {}

    dataset_ids.each_with_index do |dataset_id, d_idx|
      dataset = Opendata::Dataset.find(dataset_id) rescue nil
      next unless dataset

      dataset_relation = export_dataset(dataset, d_idx)
      sleep 1
      next unless dataset_relation

      @dataset_relations[dataset_relation.rel_id] = dataset_relation

      exported_dataset = @package.package_show(dataset_relation.rel_id)
      exported_resources = exported_dataset["resources"]

      resources_relations = []
      dataset.resources.each_with_index do |resource, r_idx|
        resources_relation = export_resource(resource, dataset_relation, exported_resources, d_idx, r_idx)
        sleep 1
        next unless resources_relation

        @resource_relations[resources_relation.rel_id] = resources_relation
      end
    end

    destroy_unimported
  end

  def export_dataset(dataset, d_idx)
    dataset_relation = Opendata::Harvest::Exporter::DatasetRelation.exported(self, dataset)

    if dataset_relation
      put_log "#{d_idx} : update dataset #{dataset.name} #{dataset.uuid}"

      # patch dataset
      result = @package.package_patch(
        dataset_relation.rel_id,
        dataset_update_params(dataset),
        api_key
      )

      attributes = {
        exporter: self,
        dataset: dataset,
        uuid: dataset.uuid,
        rel_id: result["id"]
      }
      dataset_relation.attributes = attributes
      dataset_relation.update!
    else
      put_log "#{d_idx} : create dataset #{dataset.name} #{dataset.uuid}"
      result = package.dataset_purge(dataset.uuid, api_key) rescue false

      # create dataset
      result = @package.package_create(
        dataset_create_params(dataset),
        api_key
      )

      dataset_relation = Opendata::Harvest::Exporter::DatasetRelation.new
      attributes = {
        exporter: self,
        dataset: dataset,
        uuid: dataset.uuid,
        rel_id: result["id"]
      }
      dataset_relation.attributes = attributes
      dataset_relation.save!
    end

    dataset_relation
  rescue => e
    message = "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}"
    put_log message
    nil
  end

  def export_resource(resource, dataset_relation, exported_resources, d_idx, r_idx)
    resource_relation = dataset_relation.rel_resources.select { |r| r.uuid == resource.uuid }.first

    if resource_relation

      if resource_relation.revision_id == resource.revision_id
        put_log "#{d_idx}-#{r_idx} : same revision #{resource.name} #{resource.uuid}"

        attributes = {
          uuid: resource.uuid,
          revision_id: resource.revision_id,
          rel_id: resource_relation.rel_id,
          rel_revision_id: resource.revision_id
        }
      else
        put_log "#{d_idx}-#{r_idx} : update resource #{resource.name} #{resource.uuid}"

        # update resource
        result = @package.resource_update(
          resource_relation.rel_id,
          resource_update_params(resource),
          api_key,
          (resource.source_url.present? ? nil : resource.file)
        )

        attributes = {
          uuid: resource.uuid,
          revision_id: resource.revision_id,
          rel_id: result["id"],
          rel_revision_id: result["revision_id"]
        }
      end
      resource_relation.attributes = attributes
      resource_relation.update!

    else
      put_log "#{d_idx}-#{r_idx} : create resource #{resource.name} #{resource.uuid}"

      # create resource
      result = @package.resource_create(
        dataset_relation.rel_id,
        resource_create_params(resource),
        api_key,
        (resource.source_url.present? ? nil : resource.file)
      )

      resource_relation = Opendata::Harvest::Exporter::ResourceRelation.new
      attributes = {
        rel_dataset: dataset_relation,
        uuid: resource.uuid,
        revision_id: resource.revision_id,
        rel_id: result["id"],
        rel_revision_id: result["revision_id"]
      }
      resource_relation.attributes = attributes
      resource_relation.save!
    end

    resource_relation
  rescue => e
    message = "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}"
    put_log message
    nil
  end

  def destroy_unimported
    list = @package.package_list
    list.each_with_index do |name, idx|
      dataset_attributes = @package.package_show(name)

      dataset_relation = @dataset_relations[dataset_attributes["id"]]
      if dataset_relation.nil?

        # purge dataset
        put_log "purge dataset #{dataset_attributes["id"]}"
        begin
          @package.dataset_purge(dataset_attributes["id"], api_key)
        rescue => e
          message = "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}"
          put_log message
        end

        self.deleted_resources += dataset_attributes["resources"].map { |r| r["id"] }

      else

        dataset_attributes["resources"].each do |resource_attributes|
          resource_relation = @resource_relations[resource_attributes["id"]]
          next if resource_relation

          # delete resourcse
          put_log "delete resource #{resource_attributes["id"]}"
          begin
            @package.resource_delete(resource_attributes["id"], api_key)
          rescue => e
            message = "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}"
            put_log message
          end

          self.deleted_resources << resource_attributes["id"]
        end

        # remove resource relations
        dataset_relation.rel_resources.each do |relation|
          next if @resource_relations[relation.rel_id]
          relation.destroy
        end

      end
    end

    dataset_relations.each do |relation|
      next if @dataset_relations[relation.rel_id]
      relation.destroy
    end
  end

  def dataset_owner_org(dataset)
    owner_org = nil
    owner_org_settings.each do |setting|
      owner_org = setting.ckan_id if setting.match?(dataset)
    end
    owner_org
  end

  def dataset_groups(dataset)
    groups = []
    group_settings.each do |setting|
      groups << { id: setting.ckan_id } if setting.match?(dataset)
    end
    groups
  end

  def dataset_license_id(dataset)
    license_ids = dataset.resources.map { |r| r.license.uid }.select(&:present?).uniq
    return nil if license_ids.blank?

    return license_ids[0] if license_ids.size == 1

    put_log "ambiguous dataset license, ckan could not set license in resource"
    nil
  end

  def dataset_create_params(dataset)
    params = {
      name: dataset.uuid,
      title: dataset.name,
      notes: dataset.text,
      metadata_created: dataset.created.utc.strftime('%Y-%m-%d %H:%M:%S'), # not accepted
      metadata_modified: dataset.updated.utc.strftime('%Y-%m-%d %H:%M:%S') # not accepted
    }
    owner_org = dataset_owner_org(dataset)
    groups = dataset_groups(dataset)
    license_id = dataset_license_id(dataset)

    params[:owner_org] = owner_org if owner_org.present?
    params[:groups] = groups if groups.present?
    params[:license_id] = license_id if license_id.present?
    params[:author] = dataset.author_name if dataset.author_name.present?

    params
  end

  def dataset_update_params(dataset)
    params = {
      name: dataset.uuid,
      title: dataset.name,
      notes: dataset.text,
      metadata_created: dataset.created.utc.strftime('%Y-%m-%d %H:%M:%S'), # not accepted
      metadata_modified: dataset.updated.utc.strftime('%Y-%m-%d %H:%M:%S') # not accepted
    }
    owner_org = dataset_owner_org(dataset)
    groups = dataset_groups(dataset)
    license_id = dataset_license_id(dataset)

    params[:owner_org] = owner_org if owner_org.present?
    params[:groups] = groups if groups.present?
    params[:license_id] = license_id if license_id.present?

    params
  end

  def resource_create_params(resource)
    params = {
      name: resource.name,
      url: (resource.source_url.presence || resource.file.filename),
      description: resource.text,
      format: resource.format
    }
    params
  end

  def resource_update_params(resource)
    params = {
      name: resource.name,
      url: (resource.source_url.presence || resource.file.filename),
      description: resource.text,
      format: resource.format
    }
    params
  end
end
