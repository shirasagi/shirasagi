# coding: utf-8
class RelatedPages::SearchController < ApplicationController
  include Cms::BaseFilter
  
  public
    def index
      render layout: "ss/ajax"
    end

    def search
      @cur_site = SS::Site.find_by host: params[:host]
      @query = params[:q]

      if @query.present? && @cur_site.present?
        @query = @query.split(/[\s　]+/).map { |q| { name: /#{q}/ } }
        @model = Cms::Page
        @items = @model.site(@cur_site).
          where(deleted: nil).
          and(@query).
          entries

        json = @items.map do |item|
          [ item.id,
            { name: item.name,
              filename: item.filename,
              updated: item.updated.strftime("%Y/%m/%d %H:%M"),
              url: "http://#{@cur_site.domain}#{item.url}" } 
          ]
        end.to_h.to_json
      else
        json = {}.to_json
      end

      respond_to do |format|
        format.html { raise "404" }
        format.json { render json: json }
      end
    end
end
