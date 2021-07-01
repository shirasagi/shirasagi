module Opendata::DatasetSearchable
  extend ActiveSupport::Concern

  module ClassMethods
    def search_params
      params = []
      params << :keyword
      params << :tag
      params << :area_id
      params << :category_id
      params << :estat_category_id
      params << :dataset_group
      params << :dataset_group_id
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
      criteria = self.all
      return criteria if params.blank?
      [ :search_keyword, :search_ids, :search_name, :search_tag, :search_area_id, :search_category_id, :search_estat_category_id,
        :search_dataset_group, :search_dataset_group_id, :search_format, :search_license_id, :search_poster ].each do |m|
        criteria = criteria.send(m, params)
      end

      criteria
    end

    def search_keyword(params)
      return all if params.blank? || params[:keyword].blank?

      option = params[:option].presence || 'all_keywords'
      method = option == 'all_keywords' ? 'and' : 'any'
      all.keyword_in(
        params[:keyword],
        :name,
        :text,
        "resources.name",
        "resources.filename",
        "resources.text",
        "url_resources.name",
        "url_resources.filename",
        "url_resources.text",
        method: method
      )
    end

    def search_ids(params)
      return all if params.blank? || params[:ids].blank?
      all.any_in(id: params[:ids].split(/,/))
    end

    def search_name(params)
      return all if params.blank? || params[:name].blank?

      if params[:modal].present?
        words = params[:name].split(/[\s　]+/).uniq.compact.map { |w| /#{::Regexp.escape(w)}/i }
        all.all_in name: words
      else
        all.keyword_in (params[:keyword].presence || params[:name]), :name
      end
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

    def search_estat_category_id(params)
      return all if params.blank? || params[:estat_category_id].blank?

      estat_category_id = params[:estat_category_id].to_i
      estat_category_node = Cms::Node.site(params[:site]).and_public.where(id: estat_category_id).first
      return all if estat_category_node.blank?

      estat_category_ids = [ estat_category_id ]
      estat_category_node.all_children.and_public.each do |child|
        estat_category_ids << child.id
      end

      operator = params[:option].presence == 'any_conditions' ? "$or" : "$and"
      all.where(operator => [ estat_category_ids: { "$in" => estat_category_ids } ])
    end

    def search_dataset_group(params)
      return all if params.blank? || params[:dataset_group].blank?

      site = params[:site]
      groups = Opendata::DatasetGroup.site(site).and_public.search_text(params[:dataset_group])
      groups = groups.pluck(:id).presence || [-1]
      operator = params[:option].presence == 'any_conditions' ? "$or" : "$and"
      all.where(operator => [ dataset_group_ids: { "$in" => groups } ])
    end

    def search_dataset_group_id(params)
      return all if params.blank? || params[:dataset_group_id].blank?

      operator = params[:option].presence == 'any_conditions' ? "$or" : "$and"
      all.where(operator => [ dataset_group_ids: params[:dataset_group_id].to_i ])
    end

    def search_format(params)
      return all if params.blank? || params[:format].blank?

      option = params[:option].presence || 'all_keywords'
      method = option == 'any_conditions' ? 'any' : 'and'
      all.formast_is(params[:format].upcase, "resources.format", "url_resources.format", method: method)
    end

    def search_license_id(params)
      return all if params.blank? || params[:license_id].blank?

      option = params[:option].presence || 'all_keywords'
      method = option == 'any_conditions' ? 'any' : 'and'
      all.license_is(params[:license_id].to_i, "resources.license_id", "url_resources.license_id", method: method)
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
