module Gws::Addon::Portal::Portlet
  module Survey
    extend ActiveSupport::Concern
    extend SS::Addon

    set_addon_type :gws_portlet

    included do
      field :survey_answered_state, type: String, default: "unanswered"
      field :survey_sort, type: String, default: "due_date"
      embeds_ids :survey_categories, class_name: "Gws::Survey::Category"
      permit_params :survey_answered_state, :survey_sort, survey_category_ids: []
    end

    def survey_answered_state_options
      %w(unanswered answered).map { |m| [I18n.t("gws/survey.options.answered_state.#{m}"), m] }
    end

    def survey_sort_options
      %w(due_date updated).map { |m| [I18n.t("gws/survey.options.sort.#{m}"), m] }
    end

    def survey_sort_hash
      case survey_sort
      when "updated"
        { updated: -1, order: 1 }
      else
        { due_date: 1, order: 1 }
      end
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

      Gws::Survey::Form.site(portal.site).
        without_deleted.
        and_public.
        readable(user, site: portal.site).
        search(search).
        order_by(survey_sort_hash).
        page(1).
        per(limit)
    end
  end
end
