module Opendata::Api::GroupShowFilter
  extend ActiveSupport::Concern
  include Opendata::Api

  private
    def group_show_check(id)

      id_message = []
      id_message << "Missing value" if id.blank?

      messages = {}
      messages[:name_or_id] = id_message if !id_message.empty?

      check_count = id_message.size
      if check_count > 0
        error = {__type: "Validation Error"}
        messages.each do |key, value|
          error[key] = value
        end
      end

      return error
    end

  public
    def group_show
      help = SS.config.opendata.api["group_show_help"]
      id = params[:id]
      id = URI.decode(id) if !id.nil?
      include_datasets = params[:include_datasets] || "true"

      error = group_show_check(id)
      if error.present?
        render json: {help: help, success: false, error: error} and return
      end

      groups = Opendata::DatasetGroup.site(@cur_site).public
      groups = groups.any_of({"id" => id}, {"name" => id}).order_by(name: 1)

      if groups.count > 0
        group = groups[0]
        datasets = Opendata::Dataset.site(@cur_site).public.any_in dataset_group_ids: group[:id]
        group[:package_count] = datasets.count
        group[:packages] = convert_packages(datasets) if include_datasets =~ /^true$/i
        res = {help: help, success: true, result: group}
      else
        res = {help: help, success: false}
        res[:error] = {message: "Not found", __type: "Not Found Error"}
      end

      render json: res
    end

end
