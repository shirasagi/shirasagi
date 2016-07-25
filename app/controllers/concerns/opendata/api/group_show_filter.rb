module Opendata::Api::GroupShowFilter
  extend ActiveSupport::Concern
  include Opendata::Api

  private
    def group_show_check(id)

      id_messages = []
      id_messages << "Missing value" if id.blank?

      messages = {}
      messages[:name_or_id] = id_messages if id_messages.size > 0

      if messages.size > 0
        error = {__type: "Validation Error"}
        error = error.merge(messages)
      end

      return error
    end

  public
    def group_show
      help = t("opendata.api.group_show_help")
      id = params[:id]
      id = URI.decode(id) if id
      include_datasets = params[:include_datasets] || "true"

      error = group_show_check(id)
      if error
        render json: {help: help, success: false, error: error} and return
      end

      groups = Opendata::DatasetGroup.site(@cur_site).and_public
      groups = groups.any_of({"id" => id}, {"name" => id}).order_by(name: 1)

      if groups.count > 0
        group = convert_dataset_group(groups[0][:id])
        datasets = Opendata::Dataset.site(@cur_site).and_public.any_in dataset_group_ids: group[:id]
        group[:package_count] = datasets.count
        if include_datasets =~ /^true$/i
          group[:packages] = convert_packages(datasets)
        else
          group[:packages] = []
        end

        res = {help: help, success: true, result: group}
      else
        res = {help: help, success: false}
        res[:error] = {message: "Not found", __type: "Not Found Error"}
      end

      render json: res
    end

end
