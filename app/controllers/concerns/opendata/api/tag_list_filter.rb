module Opendata::Api::TagListFilter
  extend ActiveSupport::Concern
  include Opendata::Api

  def tag_list
    help = t("opendata.api.tag_list_help")

    query = params[:query]
    query = Addressable::URI.unencode(query) if query
    #vocabulary_id = params[:vocabulary_id]
    #all_fields = params[:all_fields] || false

    tags = Opendata::Dataset.site(@cur_site).and_public.get_tag_list(query)

    tag_list = []
    tags.each do |tag|
      tag_name = tag["name"]
      tag_list << tag["name"] if query.nil? || (query.present? && tag_name =~ /^.*#{::Regexp.escape(query)}.*$/i)
    end

    res = {help: help, success: true, result: tag_list}
    render json: res
  end
end
