module History::Searchable
  extend ActiveSupport::Concern

  module ClassMethods
    def search(params)
      criteria = self.where({})
      return criteria if params.blank?

      if params[:operation_target_opts].try(:match, /action|controller/)
        criteria = search_except_ref_coll(params, criteria)
        return criteria
      end

      if params[:keyword].present?
        words = params[:keyword].split(/[\s　]+/).uniq.compact if params[:keyword].is_a?(String)
        words = words[0..4]
        cond  = words.map do |word|
          inner_cond = []

          # action
          inner_cond << { action: word }

          # controller
          inner_cond << { controller: word.pluralize }

          models = I18n.t("mongoid.models").invert
          inner_cond << { controller: models[word].to_s.pluralize } if models[word].present?

          # session_id
          inner_cond << { session_id: word }

          # request_id
          inner_cond << { request_id: word }

          # user_name
          user_ids = SS::User.where(name: /#{::Regexp.escape(word)}/i).pluck(:id)
          inner_cond << { user_id: { "$in" => user_ids } } if user_ids.present?

          #url
          inner_cond << { url: word }

          # page_url
          inner_cond << { page_url: word }

          #behavior
          if word == I18n.t("history.behavior.attachment")
            inner_cond << { behavior: "attachment" }
          elsif word == I18n.t("history.behavior.paste")
            inner_cond << { behavior: "paste" }
          end

          { "$or" => inner_cond }
        end
        criteria = criteria.where("$and" => cond)

        if params[:operator_keyword].present?
          criteria = operator_search(criteria, params)
        end
      elsif params[:operator_keyword].present?
        criteria = operator_search(criteria, params)
      end

      if params[:operation_target_opts] == 'all'
        criteria
      elsif params[:operation_target_opts].present?
        criteria = criteria.where(ref_coll: params[:operation_target_opts])
      end
      criteria
    end

    def search_except_ref_coll(params, criteria)
      if params[:keyword].present?
        case params[:operation_target_opts]
        when "controller"
          criteria = criteria.where(controller: params[:keyword])
        else #action
          criteria = criteria.where(action: params[:keyword])
        end
      end

      criteria = operator_search(criteria, params) if params[:operator_keyword].present?
      criteria
    end

    def operator_search(criteria, params)
      word = params[:operator_keyword]

      case params[:operator_target_opts]
      when "user"
        user_id = SS::User.find_by(name: word).id
        criteria = criteria.where(user_id: user_id)
      else #group
        group_id = Cms::Group.find_by(name: word).id
        criteria = criteria.in(group_ids: group_id)
      end

      criteria
    end
  end
end
