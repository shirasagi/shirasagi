module Opendata::Api::GroupShowFilter
  extend ActiveSupport::Concern
  include Opendata::Api

  private

  def group_show_check(id)

    id_messages = []
    id_messages << "Missing value" if id.blank?

    messages = {}
    messages[:name_or_id] = id_messages if id_messages.present?

    if messages.present?
      error = {__type: "Validation Error"}
      error = error.merge(messages)
    end

    return error
  end

  public

  def group_show
    help = t("opendata.api.group_show_help")
    id = params[:id]
    id = Addressable::URI.unencode(id) if id

    error = group_show_check(id)
    if error
      render json: {help: help, success: false, error: error} and return
    end

    dataset_group = Opendata::DatasetGroup.site(@cur_site).and_public.
      any_of({"id" => id}, {"name" => id}).order_by(name: 1).first

    if dataset_group
      datasets = Opendata::Dataset.site(@cur_site).and_public.in(dataset_group_ids: dataset_group.id)

      result = convert_dataset_group(dataset_group)
      result[:package_count] = datasets.count
      result[:packages] = convert_packages(datasets)

      res = {help: help, success: true, result: result}
    else
      res = {help: help, success: false}
      res[:error] = {message: "Not found", __type: "Not Found Error"}
    end

    render json: res
  end

end
