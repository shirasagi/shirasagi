module Opendata::Api::PackageSearchFilter
  extend ActiveSupport::Concern
  include Opendata::Api

  private
    def package_search_check(rows, start)

      rows_messages = []
      start_messages = []

      check_num(rows, rows_messages)
      check_num(start, start_messages)

      messages = {}
      messages[:rows] = rows_messages if rows_messages.size > 0
      messages[:start] = start_messages if start_messages.size > 0

      if messages.size > 0
        error = {__type: "Validation Error"}
        error = error.merge(messages)
      end

      return error
    end

  public
    def package_search

      help = SS.config.opendata.api["package_search_help"]

      query = params[:q] || ":"
      rows = params[:rows]
      start = params[:start]

      error = package_search_check(rows, start)
      if error
        render json: {help: help, success: false, error: error} and return
      end

      datasets = Opendata::Dataset.site(@cur_site).public.search({keyword: URI.decode(query)})

      all_count = datasets.count
      datasets = datasets.skip(start) if start
      datasets = datasets[0, rows.to_i] if rows
      result = {count: all_count, results: convert_packages(datasets)}
      res = {help: help, success: true, result: result}

      render json: res

    end

end
