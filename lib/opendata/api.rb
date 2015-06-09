module Opendata::Api

  public
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

      member_id = dataset[:member_id]
      user_id = dataset[:user_id]

      if member_id
        member = get_member(member_id)
        author = member[:author]
        author_email = member[:author_email]
      elsif user_id
        user = get_user(user_id)
        author = user[:author]
        author_email = user[:author_email]
      end

      package[:private] = dataset[:state]
      package[:revision_timestamp] = dataset[:released]
      package[:id] = dataset[:_id]
      package[:metadata_created] = dataset[:created]
      package[:metadata_modified] = dataset[:updated]
      package[:author] = author
      package[:author_email] = author_email
      package[:type] = "dataset"
      package[:resources] = convert_resources(dataset[:resources])
      package[:num_resources] = dataset.resources.size
      package[:tags] = convert_tags(dataset)
      package[:groups] = convert_dataset_groups(dataset[:dataset_group_ids])
      package[:license_id] = dataset[:license]
      package[:name] = dataset[:name]
      package[:notes] = dataset[:text]
      package[:title] = dataset[:name]

      package[:permission_level] = dataset[:permission_level]
      package[:member_id] = dataset[:member_id]
      package[:user_id] = dataset[:user_id]
      package[:site_id] = dataset[:site_id]
      package[:filename] = dataset[:filename]
      package[:route] = dataset[:route]
      package[:depth] = dataset[:depth]
      package[:order] = dataset[:order]
      package[:category_ids] = dataset[:category_ids]
      package[:area_ids] = dataset[:area_ids]
      package[:related_page_ids] = dataset[:related_page_ids]
      package[:related_url] = dataset[:related_url]
      package[:point] = dataset[:point]
      package[:downloaded] = dataset[:downloaded]

      return package
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
      package_resource[:filename] = resource[:filename]
      package_resource[:created] = resource[:created]
      package_resource[:filename] = resource[:filename]
      package_resource[:license_id] = resource[:license_id]
      package_resource[:rdf_iri] = resource[:rdf_iri]
      package_resource[:rdf_error] = resource[:rdf_error]

      return package_resource
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

      dataset_group = Opendata::DatasetGroup.site(@cur_site).public.where(id: group_id).first

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

      user = SS::User.find(user_id)
      if user
        package_user[:author] = user[:name]
        package_user[:author_email] = user[:email]
      end

      return package_user
    end

end