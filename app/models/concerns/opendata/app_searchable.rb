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
      criteria = self.where({})
      return criteria if params.blank?

      SEARCH_HANDLERS.each do |handler|
        criteria = send(handler, params, criteria)
      end

      criteria
    end

    private
      SEARCH_HANDLERS = [
        :search_keyword, :search_name, :search_tag, :search_area_id, :search_category_id,
        :search_license, :search_poster ].freeze

      def search_keyword(params, criteria)
        if params[:keyword].present?
          option = params[:option].presence || 'all_keywords'
          method = option == 'all_keywords' ? 'and' : 'any'
          criteria = criteria.keyword_in params[:keyword],
            :name, :text, "appfiles.name", "appfiles.filename", "appfiles.text", method: method
        end
        criteria
      end

      def search_name(params, criteria)
        criteria = criteria.keyword_in params[:keyword], :name if params[:name].present?
        criteria
      end

      def search_tag(params, criteria)
        operator = params[:option].presence == 'any_conditions' ? "$or" : "$and"
        criteria = criteria.where(operator => [ tags: params[:tag] ]) if params[:tag].present?
        criteria
      end

      def search_area_id(params, criteria)
        operator = params[:option].presence == 'any_conditions' ? "$or" : "$and"
        criteria = criteria.where(operator => [ area_ids: params[:area_id].to_i ]) if params[:area_id].present?
        criteria
      end

      def search_category_id(params, criteria)
        return criteria if params[:category_id].blank?

        category_id = params[:category_id].to_i
        category_node = Cms::Node.site(params[:site]).and_public.where(id: category_id).first
        return criteria if category_node.blank?

        category_ids = [ category_id ]
        category_node.all_children.and_public.each do |child|
          category_ids << child.id
        end

        operator = params[:option].presence == 'any_conditions' ? "$or" : "$and"
        criteria.where(operator => [ category_ids: { '$in' => category_ids } ])
      end

      def search_license(params, criteria)
        operator = params[:option].presence == 'any_conditions' ? "$or" : "$and"
        criteria = criteria.where(operator => [ license: params[:license] ]) if params[:license].present?
        criteria
      end

      def search_poster(params, criteria)
        if params[:poster].present?
          cond = {}
          cond = { :workflow_member_id.exists => true } if params[:poster] == "member"
          cond = { :workflow_member_id => nil } if params[:poster] == "admin"
          operator = params[:option].presence == 'any_conditions' ? "$or" : "$and"
          criteria = criteria.where(operator => cond)
        end
        criteria
      end
  end
end
