module Opendata::DatasetSearchable
  extend ActiveSupport::Concern

  module ClassMethods
    def search_params
      params = []
      params << :keyword
      params << :tag
      params << :area_id
      params << :category_id
      params << :dataset_group
      params << :format
      params << :license_id
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
      [ :search_keyword, :search_ids, :search_name, :search_tag, :search_area_id, :search_category_id,
        :search_dataset_group, :search_format, :search_license_id, :search_poster, ].each do |m|
        criteria = send(m, params, criteria)
      end

      criteria
    end

    private
      def search_keyword(params, criteria)
        if params[:keyword].present?
          option = params[:option].presence || 'all_keywords'
          method = option == 'all_keywords' ? 'and' : 'any'
          criteria = criteria.keyword_in params[:keyword],
            :name, :text, "resources.name", "resources.filename", "resources.text",
            "url_resources.name", "url_resources.filename", "url_resources.text",
            method: method
        end
        criteria
      end

      def search_ids(params, criteria)
        if params[:ids].present?
          criteria = criteria.any_in id: params[:ids].split(/,/)
        end
        criteria
      end

      def search_name(params, criteria)
        if params[:name].present?
          if params[:modal].present?
            words = params[:name].split(/[\s　]+/).uniq.compact.map {|w| /#{Regexp.escape(w)}/i }
            criteria = criteria.all_in name: words
          else
            criteria = criteria.keyword_in params[:keyword], :name
          end
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

        category_id = params[:category_id].to_i
        category_node = Cms::Node.site(params[:site]).and_public.where(id: category_id).first
        return criteria if category_node.blank?

        category_ids = [ category_id ]
        category_node.all_children.and_public.each do |child|
          category_ids << child.id
        end

        operator = params[:option].presence == 'any_conditions' ? "$or" : "$and"
        criteria.where(operator => [ category_ids: { "$in" => category_ids } ])
      end

      def search_dataset_group(params, criteria)
        if params[:dataset_group].present?
          site = params[:site]
          groups = Opendata::DatasetGroup.site(site).and_public.search_text(params[:dataset_group])
          groups = groups.pluck(:id).presence || [-1]
          operator = params[:option].presence == 'any_conditions' ? "$or" : "$and"
          criteria = criteria.where(operator => [ dataset_group_ids: { "$in" => groups } ])
        end
        criteria
      end

      def search_format(params, criteria)
        if params[:format].present?
          option = params[:option].presence || 'all_keywords'
          method = option == 'any_conditions' ? 'any' : 'and'
          criteria = criteria.formast_is params[:format].upcase, "resources.format", "url_resources.format", method: method
        end
        criteria
      end

      def search_license_id(params, criteria)
        if params[:license_id].present?
          option = params[:option].presence || 'all_keywords'
          method = option == 'any_conditions' ? 'any' : 'and'
          criteria = criteria.license_is params[:license_id].to_i,
                                         "resources.license_id", "url_resources.license_id", method: method
        end
        criteria
      end

      def search_poster(params, criteria)
        poster = params[:poster]
        return criteria if poster.blank?

        cond = case poster
               when "member"
                 { :workflow_member_id.exists => true }
               when "admin"
                 { :workflow_member_id => nil }
               end
        return criteria if cond.blank?

        operator = params[:option].presence == 'any_conditions' ? "$or" : "$and"
        criteria.where(operator => [ cond ])
      end
  end
end
