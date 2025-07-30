module Opendata::Harvest::CkanApiExportInitializer
  extend ActiveSupport::Concern

  def group_list
    package = ::Opendata::Harvest::CkanPackage.new(url)

    list = package.group_list
    list.each_with_index do |name, idx|
      group_attributes = package.group_show(name)
      put_log "#{group_attributes["id"]} #{group_attributes["name"]} #{group_attributes["title"]}"
    end
  end

  def organization_list
    package = ::Opendata::Harvest::CkanPackage.new(url)

    list = package.organization_list
    list.each_with_index do |name, idx|
      attributes = package.organization_show(name)
      put_log "#{attributes["id"]} #{attributes["name"]} #{attributes["title"]}"
    end
  end

  def dataset_purge
    package = ::Opendata::Harvest::CkanPackage.new(url)

    list = package.package_list
    list.each_with_index do |name, idx|
      dataset_attributes = package.package_show(name)
      id = dataset_attributes["id"]
      resources = dataset_attributes["resources"]

      resources.each_with_index do |resource_attributes, r_idx|
        resource_id = resource_attributes["id"]
        self.deleted_resources << resource_id

        put_log "#{idx}-#{r_idx} : resource_delete #{resource_id}"
        package.resource_delete(resource_id, api_key)
      end

      put_log "#{idx} : dataset_purge #{name} #{id}"
      package.dataset_purge(id, api_key)
    end

    self.dataset_relations.destroy_all
    self.deleted_resources = []
    save!
  end

  def initialize_group
    package = ::Opendata::Harvest::CkanPackage.new(url)
    list = package.group_list
    list.each_with_index do |name, idx|
      put_log "delete #{name}"
      package.group_purge(name, api_key)
    end

    group_settings.destroy_all

    idx = 0
    Opendata::Node::Category.site(site).each do |c|
      params = { name: "ssg#{c.id}", title: c.name }
      attributes = package.group_create(params, api_key)
      put_log "#{attributes["id"]} #{attributes["name"]} #{attributes["title"]}"

      setting = Opendata::Harvest::Exporter::GroupSetting.new(exporter: self, cur_site: site)
      setting.name = attributes["title"]
      setting.ckan_id = attributes["id"]
      setting.ckan_name = attributes["name"]
      setting.order = (idx + 1) * 10
      setting.category_ids = [c.id]
      setting.save!

      idx += 1
    end

    Opendata::Node::EstatCategory.site(site).each do |c|
      params = { name: "ssg#{c.id}", title: "e-Stat #{c.name}" }
      attributes = package.group_create(params, api_key)
      put_log "#{attributes["id"]} #{attributes["name"]} #{attributes["title"]}"

      setting = Opendata::Harvest::Exporter::GroupSetting.new(exporter: self, cur_site: site)
      setting.name = attributes["title"]
      setting.ckan_id = attributes["id"]
      setting.ckan_name = attributes["name"]
      setting.order = (idx + 1) * 10
      setting.estat_category_ids = [c.id]
      setting.save!

      idx += 1
    end
  end

  def initialize_organization
    package = ::Opendata::Harvest::CkanPackage.new(url)
    list = package.organization_list
    list.each_with_index do |name, idx|
      put_log "delete #{name}"
      package.organization_purge(name, api_key)
    end

    owner_org_settings.destroy_all

    SS::Group.active.each_with_index do |g, idx|
      params = { name: "org#{g.id}", title: g.trailing_name }
      attributes = package.organization_create(params, api_key)
      put_log "#{attributes["id"]} #{attributes["name"]} #{attributes["title"]}"

      setting = Opendata::Harvest::Exporter::OwnerOrgSetting.new(exporter: self, cur_site: site)
      setting.name = attributes["title"]
      setting.ckan_id = attributes["id"]
      setting.order = (idx + 1) * 10
      setting.group_ids = [g.id]
      setting.save!
    end
  end
end
