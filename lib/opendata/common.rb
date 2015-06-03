module Opendata::Common

  public
    def get_url(url, page)
      url.sub(/\.html$/, "") + page
    end

    def aggregate_tags(page, type, limit)
      pages.aggregate_array type, limit: limit
    end
end
