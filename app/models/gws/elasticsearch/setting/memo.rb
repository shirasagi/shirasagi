class Gws::Elasticsearch::Setting::Memo
  include ActiveModel::Model
  include Gws::Elasticsearch::Setting::Base

  self.model = Gws::Memo::Message

  def menu_label
    @cur_site.menu_memo_label || I18n.t('modules.gws/memo')
  end

  def search_types
    return [] unless cur_site.menu_memo_visible?
    [ model.collection_name ]
  end

  def readable_filter
    # received messages
    query1 = {}
    query1[:bool] = {}
    query1[:bool][:must] = { term: { readable_member_ids: cur_user.id } }

    # sent messages
    query2 = {}
    query2[:bool] = {}
    query2[:bool][:must] = []
    query2[:bool][:must] << { term: { user_ids: cur_user.id } }
    query2[:bool][:must] << { bool: { must_not: { exists: { 'field' => 'deleted.sent' } } } }

    query0 = {}
    query0[:bool] = {}
    query0[:bool][:should] = [query1, query2]
    query0[:bool][:minimum_should_match] = 1

    query0

    filter_query = {}
    filter_query[:bool] = {}
    filter_query[:bool][:must] = []
    filter_query[:bool][:must] += and_public
    filter_query[:bool][:must] << query0
    filter_query
  end

  def manageable_filter
    nil
  end
end
