module Gws::Tabular::File::Search
  extend ActiveSupport::Concern

  module ClassMethods
    def search(params = nil)
      criteria = all
      return criteria if params.blank?

      search_handlers.each do |handler|
        criteria = criteria.send(handler, params)
      rescue => e
        Rails.logger.warn("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
      end

      criteria
    end

    def search_keyword(params)
      return all if params[:keyword].blank?
      all.keyword_in(params[:keyword], *keyword_fields)
    end

    def search_act(params)
      Gws::Tabular::File::ActQuery.call(self, all, **params.to_h.slice(:cur_site, :cur_user, :cur_form, :act))
    end
  end
end
