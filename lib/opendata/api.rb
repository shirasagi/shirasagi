module Opendata::Api

  def check_num(num, messages)
    if num
      if integer?(num)
        if num.to_i < 0
          messages << "Must be a natural number"
        end
      else
        messages << "Invalid integer"
      end
    end

  end

  def integer?(s)
    i = Integer(s)
    check = true
  rescue
    check = false
  end

  def convert_packages(datasets)

    packages = []

    if datasets
      datasets.each do |dataset|
        packages << convert_package(dataset)
      end
    end

    return packages
  end

  def convert_package(dataset)
    package = {}

    author, author_email = get_author(dataset)

    # special attributes conversion
    package[:author] = author
    package[:author_email] = author_email
    package[:type] = "dataset"
    package[:resources] = convert_resources(dataset[:resources]) +
                          convert_url_resources(dataset[:url_resources])
    package[:num_resources] = get_num_resources(dataset[:resources]) +
                              get_num_url_resources(dataset[:url_resources])
    package[:tags] = convert_tags(dataset)
    package[:groups] = convert_dataset_groups(dataset[:dataset_group_ids])

    # map attributes
    [ [ :private, :state ], [ :revision_timestamp, :released ], [ :id, :_id ], [ :metadata_created, :created ],
      [ :metadata_modified, :updated ], [ :license_id, :license ], [ :name, :name ], [ :notes, :text ],
      [ :title, :name ] ].each do |to, from|
      package[to] = dataset[from]
    end

    # simply copy attributes
    [ :permission_level, :member_id, :user_id, :site_id, :filename, :route, :depth, :order, :category_ids, :area_ids,
      :related_page_ids, :related_url, :point, :downloaded ].each do |k|
      package[k] = dataset[k]
    end

    return package
  end

  def get_num_resources(dataset_resources)
    return dataset_resources ? dataset_resources.size : 0
  end

  def convert_resources(dataset_resources)
    package_resources = []

    resources = dataset_resources || []
    resources.each do |resource|
      package_resources << convert_resource(resource)

    end

    return package_resources
  end

  def convert_resource(resource)
    package_resource = {}

    package_resource[:id] = resource[:file_id]
    package_resource[:last_modified] = resource[:updated]
    package_resource[:description] = resource[:text]
    package_resource[:format] = resource[:format]
    package_resource[:name] = resource[:name]
    package_resource[:created] = resource[:created]
    package_resource[:filename] = resource[:filename]
    package_resource[:license_id] = resource[:license_id]
    package_resource[:rdf_iri] = resource[:rdf_iri]
    package_resource[:rdf_error] = resource[:rdf_error]

    return package_resource
  end

  def get_num_url_resources(dataset_url_resources)
    return dataset_url_resources ? dataset_url_resources.size : 0
  end

  def convert_url_resources(dataset_url_resources)
    package_url_resources = []

    url_resources = dataset_url_resources || []
    url_resources.each do |url_resource|
      package_url_resources << convert_url_resource(url_resource)
    end

    return package_url_resources
  end

  def convert_url_resource(url_resource)
    package_url_resource = {}

    package_url_resource[:id] = url_resource[:file_id]
    package_url_resource[:last_modified] = url_resource[:updated]
    package_url_resource[:description] = url_resource[:text]
    package_url_resource[:format] = url_resource[:format]
    package_url_resource[:name] = url_resource[:name]
    package_url_resource[:created] = url_resource[:created]
    package_url_resource[:filename] = url_resource[:filename]
    package_url_resource[:license_id] = url_resource[:license_id]
    package_url_resource[:rdf_iri] = url_resource[:rdf_iri]
    package_url_resource[:rdf_error] = url_resource[:rdf_error]
    package_url_resource[:originai_url] = url_resource[:original_url]
    package_url_resource[:original_updated] = url_resource[:original_updated]
    package_url_resource[:crawl_state] = url_resource[:crawl_state]
    package_url_resource[:crawl_update] = url_resource[:crawl_update]

    return package_url_resource
  end

  def convert_tags(dataset)
    package_tags = []

    tags = dataset[:tags] || []
    tags.each do |tag|
      package_tag = {}
      package_tag[:display_name] = tag
      package_tag[:name] = tag
      package_tag[:revision_timestamp] = dataset[:released]
      package_tag[:state] = dataset[:state]
      package_tags << package_tag
    end

    return package_tags
  end

  def convert_dataset_groups(dataset_group_ids)
    package_groups = []

    group_ids = dataset_group_ids || []
    group_ids.each do |group_id|
      package_groups << convert_dataset_group(group_id)
    end

    return package_groups
  end

  def convert_dataset_group(group_id)
    package_group = {}

    dataset_group = Opendata::DatasetGroup.site(@cur_site).and_public.where(id: group_id).first

    if dataset_group
      package_group[:display_name] = dataset_group[:name]
      package_group[:title] = dataset_group[:name]
      package_group[:id] = dataset_group[:_id]
      package_group[:name] = dataset_group[:name]
    end

    return package_group
  end

  def get_member(member_id)
    package_member = {}

    member = Opendata::Member.site(@cur_site).where(id: member_id).first
    if member
      package_member[:author] = member[:name]
      package_member[:author_email] = member[:email]
    end

    return package_member
  end

  def get_user(user_id)
    package_user = {}

    user = Cms::User.site(@cur_site).where(id: user_id).first
    if user
      package_user[:author] = user[:name]
      package_user[:author_email] = user[:email]
    end

    return package_user
  end

  def get_author(dataset)
    if member_id = dataset[:member_id]
      member = get_member(member_id)
      return [ member[:author], member[:author_email] ]
    elsif user_id = dataset[:user_id]
      user = get_user(user_id)
      return [ user[:author], user[:author_email] ]
    end

    nil
  end
end