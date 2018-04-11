module Opendata::AppSearchable
  extend ActiveSupport::Concern

  module ClassMethods
    def search_params
      params = []
      params << :keyword
      params << :tag
      params << :area_id
      params << :category_id
      params << :license
      params << :option
      params
    end

    def search_options
      %w(all_keywords any_keywords any_conditions).map do |w|
        [I18n.t("opendata.search_options.#{w}"), w]
      end
    end

    def search(params)
      criteria = self.all
      return criteria if params.blank?

      SEARCH_HANDLERS.each do |handler|
        criteria = criteria.send(handler, params)
      end

      criteria
    end

    SEARCH_HANDLERS = [
      :search_keyword, :search_name, :search_tag, :search_area_id, :search_category_id,
      :search_license, :search_poster ].freeze

    def search_keyword(params)
      return all if params.blank? || params[:keyword].blank?

      option = params[:option].presence || 'all_keywords'
      method = option == 'all_keywords' ? 'and' : 'any'
      all.keyword_in params[:keyword],
        :name, :text, "appfiles.name", "appfiles.filename", "appfiles.text", method: method
    end

    def search_name(params)
      return all if params.blank? || params[:name].blank?
      all.keyword_in params[:keyword], :name
    end

    def search_tag(params)
      return all if params.blank? || params[:tag].blank?

      operator = params[:option].presence == 'any_conditions' ? "$or" : "$and"
      all.where(operator => [ tags: params[:tag] ])
    end

    def search_area_id(params)
      return all if params.blank? || params[:area_id].blank?

      operator = params[:option].presence == 'any_conditions' ? "$or" : "$and"
      all.where(operator => [ area_ids: params[:area_id].to_i ])
    end

    def search_category_id(params)
      return all if params.blank? || params[:category_id].blank?

      category_id = params[:category_id].to_i
      category_node = Cms::Node.site(params[:site]).and_public.where(id: category_id).first
      return all if category_node.blank?

      category_ids = [ category_id ]
      category_node.all_children.and_public.each do |child|
        category_ids << child.id
      end

      operator = params[:option].presence == 'any_conditions' ? "$or" : "$and"
      all.where(operator => [ category_ids: { "$in" => category_ids } ])
    end

    def search_license(params)
      return all if params.blank? || params[:license].blank?

      operator = params[:option].presence == 'any_conditions' ? "$or" : "$and"
      all.where(operator => [ license: params[:license] ])
    end

    def search_poster(params)
      return all if params.blank? || params[:poster].blank?

      poster = params[:poster]
      cond = case poster
             when "member"
               { :workflow_member_id.exists => true }
             when "admin"
               { :workflow_member_id => nil }
             end
      return all if cond.blank?

      operator = params[:option].presence == 'any_conditions' ? "$or" : "$and"
      all.where(operator => [ cond ])
    end
  end
end
