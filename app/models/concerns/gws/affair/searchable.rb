module Gws::Affair::Searchable
  extend ActiveSupport::Concern
  extend SS::Translation

  module ClassMethods
    def and_state(state, user)
      criteria = all
      return criteria if state.blank?

      case state
      when 'all'
        criteria
      when 'approve'
        criteria.where(
          workflow_state: 'request',
          workflow_approvers: { '$elemMatch' => { 'user_id' => user.id, 'state' => 'request' } }
        )
      when 'mine'
        criteria.where( target_user_id: user.id )
      else
        none
      end
    end

    def search(params)
      criteria = all
      return criteria if params.blank?

      criteria = criteria.search_keyword(params)
      criteria = criteria.search_user(params)
      criteria = criteria.search_date(params)
      criteria = criteria.search_status(params)
      criteria = criteria.search_capital(params)
      criteria.search_workflow_state(params)
    end

    def search_user(params)
      return all if params[:user_id].blank?
      all.where('$or' => [ { user_id: params[:user_id] }, { target_user_id: params[:user_id] } ])
    end

    def search_date(params)
      return all if params[:year].blank? || params[:month].blank?

      start_at = Time.zone.parse("#{params[:year]} #{params[:month]}/1")
      end_at = start_at.end_of_month

      all.where('$and' => [ { "date" => { "$gte" => start_at } }, { "date" => { "$lte" => end_at } } ])
    end

    def search_keyword(params)
      return all if params[:keyword].blank?
      all.keyword_in(params[:keyword], :name, :text, 'column_values.text_index')
    end

    def search_status(params)
      return all if params[:status].blank?

      case params[:status]
      when 'result_closed'
        criteria.where(state: "approve", :result_closed.exists => true)
      when 'approve'
        criteria.where(state: "approve", :result_closed.exists => false)
      when 'request'
        criteria.where(workflow_state: "request")
      when 'draft'
        criteria.where(state: "closed").where('$or' => [ { workflow_state: nil }, { workflow_state: "cancelled" } ])
      else
        criteria
      end
    end

    def search_capital(params)
      return all if params[:capital_id].blank?

      capital = Gws::Affair::Capital.find(params[:capital_id]) rescue nil
      return all if capital.blank?

      all.where(capital_id: capital.id)
    end

    def search_workflow_state(params)
      return all if params[:workflow_state].blank?
      params[:workflow_state] == "draft" ? params[:workflow_state] = nil : params[:workflow_state]
      all.where(workflow_state: params[:workflow_state])
    end
  end
end
