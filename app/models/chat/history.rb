class Chat::History
  extend SS::Translation
  include SS::Document
  include SS::Reference::Site
  include SS::Reference::User

  index({ created: -1, id: -1, site_id: 1, node_id: 1 })

  seqid :id
  field :session_id, type: String
  field :request_id, type: String
  field :text, type: String
  field :question, type: String
  field :result, type: String
  field :suggest, type: SS::Extensions::Words
  field :click_suggest, type: String

  belongs_to :node, class_name: "Chat::Node::Bot", inverse_of: :histories
  belongs_to :prev_intent, class_name: "Chat::Intent"
  belongs_to :intent, class_name: "Chat::Intent"

  permit_params :text, :question

  def question_options
    self.class.question_options
  end

  class << self
    def search(params)
      criteria = all
      return criteria if params.blank?

      if params[:name].present?
        criteria = criteria.search_text params[:name]
      end
      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword], :session_id, :request_id, :text, :result, :suggest, :click_suggest
      end
      if params[:year].present?
        year = params[:year].to_i
        if params[:month].present?
          month = params[:month].to_i
          sdate = Date.new year, month, 1
          edate = sdate + 1.month
        else
          sdate = Date.new year, 1, 1
          edate = sdate + 1.year
        end
        criteria = criteria.where("updated" => { "$gte" => sdate, "$lt" => edate })
      end
      if params[:session_id].present?
        criteria = criteria.where(session_id: params[:session_id])
      end
      criteria
    end

    def question_options
      %w(success retry).collect do |m|
        [I18n.t("chat.options.question.#{m}"), m]
      end
    end
  end
end
