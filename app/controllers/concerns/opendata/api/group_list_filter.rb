module Opendata::Api::GroupListFilter
  extend ActiveSupport::Concern

  private
    def group_list_param_check?(sort)

      sort_message = []
      sort_values = ["name", "packages"]

      sort_message << "Cannot sort by field `#{sort}`" if !sort_values.include?(sort)

      messages = {}
      messages[:sort] = sort_message if !sort_message.empty?

      check_count = sort_message.size
      if check_count > 0
        error = {__type: "Validation Error"}
        messages.each do |key, value|
          error[key] = value
        end
      end

      return error
    end

  public
    def group_list

      help = SS.config.opendata.api["group_list_help"]

      sort = params[:sort] || "name"
      sort = sort.downcase
      groups = params[:groups]
      all_fields = params[:all_fields]

      error = group_list_param_check?(sort)
      if error.present?
        render json: {help: help, success: false, error: error} and return
      end

      @groups = Opendata::DatasetGroup.site(@cur_site).public

      group_list = []
      @groups.each do |group|
        datasets = Opendata::Dataset.site(@cur_site).public.any_in dataset_group_ids: group.id
        group_list << {id: group.id, state: group.state, name: group.name, order: group.order, packages: datasets.count}
      end

      if sort =~ /^name$/i
        group_list.sort!{|a, b| a[:name] <=> b[:name]}
      elsif sort =~ /^packages$/i
        group_list.sort!{|a, b| (b[:packages] == a[:packages]) ? a[:name] <=> b[:name] : b[:packages] <=> a[:packages]}
      end

      if all_fields.nil?
        group_name_list = []
        group_list.each do |group|
          group_name_list << group[:name]
        end
        group_list = group_name_list
      end

      res = {help: help, success: true, result: group_list}
      render json: res
    end

end