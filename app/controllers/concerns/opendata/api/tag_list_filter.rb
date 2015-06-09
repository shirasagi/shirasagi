module Opendata::Api::TagListFilter
  extend ActiveSupport::Concern
  include Opendata::Api

  public
    def tag_list
      help = SS.config.opendata.api["tag_list_help"]

      query = params[:query]
      query = URI.decode(query) if !query.nil?
      #vocabulary_id = params[:vocabulary_id]
      #all_fields = params[:all_fields] || false

      tags = Opendata::Dataset.site(@cur_site).public.get_tag_list(query)

      tag_list = []
      tags.each do |tag|
        tag_name = tag["name"]
        tag_list << tag["name"] if query.nil? || (query.present? && tag_name =~ /^.*#{query}.*$/i)
      end

      res = {help: help, success: true, result: tag_list}
      render json: res

    end

end
