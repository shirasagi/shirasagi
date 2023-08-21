module Gws::Addon::Portal::Portlet
  module Survey
    extend ActiveSupport::Concern
    extend SS::Addon

    set_addon_type :gws_portlet

    included do
      field :survey_answered_state, type: String
      field :survey_sort, type: String
      embeds_ids :survey_categories, class_name: "Gws::Survey::Category"
      permit_params :survey_answered_state, :survey_sort, survey_category_ids: []

      before_validation :set_default_survey_setting
    end

    def survey_answered_state_options
      Gws::Survey::Form.answered_state_options
    end

    def survey_sort_options
      Gws::Survey::Form.sort_options
    end

    def find_survey_items(portal, user)
      search = { site: portal.site }

      if cate = survey_categories.readable(user, site: portal.site).first
        search[:category_id] = cate.id
      end
      if survey_answered_state.present?
        search[:user] = user
        search[:answered_state] = survey_answered_state
      end

      criteria = Gws::Survey::Form.site(portal.site)
      criteria = criteria.without_deleted
      criteria = criteria.and_public
      criteria = criteria.readable(user, site: portal.site)
      criteria = criteria.search(search)
      if survey_sort.present?
        criteria = criteria.custom_order(survey_sort)
      end
      criteria = criteria.page(1)
      criteria.per(limit)
    end

    def see_more_survey_path(portal, user)
      search = {}

      folder_id = "-"

      cate = survey_categories.readable(user, site: portal.site).first
      category_id = cate ? cate.id : "-"

      if survey_answered_state.present?
        search[:answered_state] = survey_answered_state
      end
      if survey_sort.present?
        search[:sort] = survey_sort
      end
      url_helper = Rails.application.routes.url_helpers
      url_helper.gws_survey_readables_path(site: portal.site, folder_id: folder_id, category_id: category_id, s: search)
    end

    private

    def set_default_survey_setting
      site = cur_site || site
      return unless site

      if survey_answered_state.blank?
        self.survey_answered_state = site.survey_answered_state
      end
      if survey_sort.blank?
        self.survey_sort = site.survey_sort
      end
    end
  end
end
