class Gws::Elasticsearch::Setting::Memo
  include ActiveModel::Model
  include Gws::Elasticsearch::Setting::Base

  self.model = Gws::Memo::Message

  def menu_label
    @cur_site.menu_memo_label || I18n.t('modules.gws/memo')
  end
end
