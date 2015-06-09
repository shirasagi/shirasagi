module Opendata::Api::PackageSearchFilter
  extend ActiveSupport::Concern
  include Opendata::Api

  private
    def package_search_check(rows, start)

      rows_message = []
      start_message = []

      if rows
        if integer?(rows)
          if rows.to_i < 0
            rows_message << "Must be a natural number"
          end
        else
          rows_message << "Invalid integer"
        end
      end

      if start
        if integer?(start)
          if start.to_i < 0
            start_message << "Must be a natural number"
          end
        else
          start_message << "Invalid integer"
        end
      end

      messages = {}
      messages[:rows] = rows_message if rows_message.present?
      messages[:start] = start_message if start_message.present?

      check_count = rows_message.size + start_message.size
      if check_count > 0
        error = {__type: "Validation Error"}
        messages.each do |key, value|
          error[key] = value
        end
      end

      return error
    end

    def integer?(s)
      i = Integer(s)
      check = true
    rescue
      check = false
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
      datasets = datasets.limit(rows) if rows
      result = {count: all_count, results: convert_packages(datasets)}
      res = {help: help, success: true, result: result}

      render json: res

    end

end
