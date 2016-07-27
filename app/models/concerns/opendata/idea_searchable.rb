module Opendata::IdeaSearchable
  extend ActiveSupport::Concern

  module ClassMethods
    def search_params
      params = []
      params << :keyword
      params << :tag
      params << :area_id
      params << :category_id
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
      SEARCH_HANDLERS = [ :search_keyword, :search_tag, :search_area_id, :search_category_id, :search_poster ].freeze

      def search_keyword(params, criteria)
        if params[:keyword].present?
          option = params[:option].presence || 'all_keywords'
          method = option == 'all_keywords' ? 'and' : 'any'
          criteria = criteria.keyword_in params[:keyword], :name, :text, :issue, :data, :note, method: method
        end
        criteria
      end

      def search_tag(params, criteria)
        if params[:tag].present?
          operator = params[:option].presence == 'any_conditions' ? "$or" : "$and"
          criteria = criteria.where(operator => [ tags: params[:tag] ])
        end
        criteria
      end

      def search_area_id(params, criteria)
        if params[:area_id].present?
          operator = params[:option].presence == 'any_conditions' ? "$or" : "$and"
          criteria = criteria.where(operator => [ area_ids: params[:area_id].to_i ])
        end
        criteria
      end

      def search_category_id(params, criteria)
        return criteria if params[:category_id].blank?

        operator = params[:option].presence == 'any_conditions' ? "$or" : "$and"

        category_id = params[:category_id].to_i
        category_node = Cms::Node.site(params[:site]).and_public.where(id: category_id).first
        return criteria if category_node.blank?

        category_ids = [ category_id ]
        category_node.all_children.and_public.each do |child|
          category_ids << child.id
        end

        criteria.where(operator => [ category_ids: { "$in" => category_ids } ])
      end

      def search_poster(params, criteria)
        if params[:poster].present?
          cond = {}
          cond = { :workflow_member_id.exists => true } if params[:poster] == "member"
          cond = { :workflow_member_id => nil } if params[:poster] == "admin"
          operator = params[:option].presence == 'any_conditions' ? "$or" : "$and"
          criteria = criteria.where(operator => [ cond ])
        end
        criteria
      end
  end
end
