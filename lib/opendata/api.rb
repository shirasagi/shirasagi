module Opendata::Api
  def check_num(num, messages)
    num = Integer(num) rescue -1
    messages << "Must be a natural number" if num < 0
  end

  def convert_packages(datasets)
    datasets.map { |dataset| convert_package(dataset) }
  end

  def convert_package(dataset)
    package = {}

    package[:type] = "dataset"

    package[:site] = convert_site(dataset.site)
    package[:user] = convert_user(dataset.user) if dataset.user
    package[:member] = convert_member(dataset.member) if dataset.member
    package[:author] = convert_author(dataset)

    package[:id] = dataset.id
    package[:uuid] = dataset.uuid
    package[:name] = dataset.name
    package[:filename] = dataset.filename
    package[:url] = dataset.full_url
    package[:text] = dataset.text
    package[:update_plan] = dataset.update_plan
    package[:state] = dataset.state
    package[:released] = dataset.released
    package[:created] = dataset.created
    package[:updated] = dataset.updated

    package[:categories] = convert_categories(dataset)
    package[:estat_categories] = convert_estat_categories(dataset)
    package[:areas] = convert_areas(dataset)
    package[:tags] = dataset.tags.to_a

    package[:point] = dataset.point
    package[:downloaded] = dataset.downloaded
    package[:groups] = convert_groups(dataset)

    package[:resources] = convert_resources(dataset) + convert_url_resources(dataset)
    package[:num_resources] = dataset.resources.count + dataset.url_resources.count

    package
  end

  def convert_site(site)
    {
      id: site.id,
      name: site.name,
      url: site.full_url,
      created: site.created,
      updated: site.updated,
    }
  end

  def convert_author(dataset)
    dataset.author_name
  end

  def convert_user(user)
    {
      id: user.id,
      name: user.name,
      uid: user.uid,
      email: user.email,
      created: user.created,
      updated: user.updated,
    }
  end

  def convert_member(member)
    {
      id: member.id,
      name: member.name,
      email: member.email,
      created: member.created,
      updated: member.updated,
    }
  end

  def convert_group(group)
    {
      id: group.id,
      name: group.name,
      trailing_name: group.trailing_name,
      created: group.created,
      updated: group.updated,
    }
  end

  def convert_dataset_group(dataset_group)
    {
      id: dataset_group.id,
      name: dataset_group.name,
      categories: convert_categories(dataset_group),
      created: dataset_group.created,
      updated: dataset_group.updated,
    }
  end

  def convert_groups(dataset)
    dataset.groups.map { |group| convert_group(group) }
  end

  def convert_categories(dataset)
    dataset.categories.map { |category| convert_category(category) }
  end

  def convert_category(category)
    {
      id: category.id,
      name: category.name,
      filename: category.filename,
      state: category.state,
      created: category.created,
      updated: category.updated,
    }
  end

  def convert_estat_categories(dataset)
    dataset.estat_categories.map { |estat_category| convert_estat_category(estat_category) }
  end

  def convert_estat_category(estat_category)
    {
      id: estat_category.id,
      name: estat_category.name,
      filename: estat_category.filename,
      state: estat_category.state,
      created: estat_category.created,
      updated: estat_category.updated,
    }
  end

  def convert_areas(dataset)
    dataset.areas.map { |area| convert_area(area) }
  end

  def convert_area(area)
    {
      id: area.id,
      name: area.name,
      filename: area.filename,
      state: area.state,
      created: area.created,
      updated: area.updated,
    }
  end

  def convert_resources(dataset)
    dataset.resources.map { |resource| convert_resource(resource) }
  end

  def convert_resource(resource)
    package_resource = {}

    package_resource[:id] = resource.file_id
    package_resource[:uuid] = resource.uuid
    package_resource[:revision_id] = resource.revision_id
    package_resource[:name] = resource.name
    package_resource[:filename] = resource.filename
    package_resource[:text] = resource.text
    package_resource[:license] = convert_license(resource.license)
    package_resource[:rdf_iri] = resource.rdf_iri
    package_resource[:rdf_error] = resource.rdf_error
    package_resource[:created] = resource.created
    package_resource[:updated] = resource.updated
    package_resource[:download_url] = resource.download_full_url
    package_resource[:url] = resource.full_url
    package_resource[:format] = resource.format

    package_resource
  end

  def convert_url_resources(dataset)
    dataset.url_resources.map { |url_resource| convert_url_resource(url_resource) }
  end

  def convert_url_resource(url_resource)
    package_url_resource = {}

    package_url_resource[:id] = url_resource.file_id
    package_url_resource[:uuid] = url_resource.uuid
    package_url_resource[:last_modified] = url_resource.updated
    package_url_resource[:description] = url_resource.text
    package_url_resource[:format] = url_resource.format
    package_url_resource[:name] = url_resource.name
    package_url_resource[:created] = url_resource.created
    package_url_resource[:filename] = url_resource.filename
    package_url_resource[:license_id] = url_resource.license_id
    package_url_resource[:rdf_iri] = url_resource.rdf_iri
    package_url_resource[:rdf_error] = url_resource.rdf_error
    package_url_resource[:originai_url] = url_resource.original_url
    package_url_resource[:original_updated] = url_resource.original_updated
    package_url_resource[:crawl_state] = url_resource.crawl_state
    package_url_resource[:crawl_update] = url_resource.crawl_update

    package_url_resource
  end

  def convert_license(license)
    {
      id: license.id,
      name: license.name,
      uid: license.uid,
      state: license.state,
      created: license.created,
      updated: license.updated,
    }
  end
end