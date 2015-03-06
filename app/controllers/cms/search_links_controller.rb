class Cms::SearchLinksController < ApplicationController
  include Cms::SearchFilter

  public
    def index
      keyword = params[:s].try(:[], :keyword)
      option   = params[:s].try(:[], :option)

      if keyword.present?
        (option == "regexp") ? search_with_url(keyword) : search_with_regexp(keyword)
      end
    end

  private
    def search_with_url(keyword)
      words = []
      words << ("=\"/#{keyword}" =~ /\.html$/ ? "=\"/#{keyword}" : "=\"/#{keyword}/")
      words << "=\"/#{keyword.sub(/index.html$/, "")}" if keyword =~ /\/index.html$/
      words = words.join(" ")

      cond = Cms::Page.keyword_in(words, :html, :question).selector
      cond["$or"] = cond["$and"]
      cond.delete("$and")

      @pages = Cms::Page.site(@cur_site).where(cond).limit(500)
      @parts = Cms::Part.site(@cur_site).where(cond).limit(500)
      @layouts = Cms::Layout.site(@cur_site).where(cond).limit(500)
    end

    def search_with_regexp(keyword)
    end
end
