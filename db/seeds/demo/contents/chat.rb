installer = Class.new do
  include ActiveModel::Model

  attr_accessor :site

  def save_chat_category(data)
    puts data[:name]
    cond = { site_id: @site.id, node_id: data[:node_id], name: data[:name] }
    item = Chat::Category.find_or_initialize_by(cond)
    item.attributes = data
    item.save

    item
  end

  def save_chat_intent(data)
    puts data[:name]
    cond = { site_id: @site.id, node_id: data[:node_id], name: data[:name] }
    item = Chat::Intent.find_or_initialize_by(cond)
    item.attributes = data
    item.save

    item
  end

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def call
    puts "# chat"

    node = Chat::Node::Bot.where(site_id: @site._id).find_by(filename: 'chatbot')

    save_chat_category node_id: node.id, name: 'くらし・手続き', order: 10
    save_chat_category node_id: node.id, name: '子育て・教育', order: 20
    save_chat_category node_id: node.id, name: '健康・福祉', order: 30
    save_chat_category node_id: node.id, name: '観光・文化・スポーツ', order: 40
    save_chat_category node_id: node.id, name: '産業・仕事', order: 50
    save_chat_category node_id: node.id, name: '市政情報', order: 60

    array = Chat::Category.where(site_id: @site._id).map { |m| [m.name, m] }
    chat_categories = Hash[*array.flatten]

    save_chat_intent node_id: node.id, name: '戸籍について', phrase: %w(戸籍 戸籍について),
      suggest: %w(引越しの手続きについて 住民票について 印鑑登録について マイナンバーについて),
      question: 'disabled', site_search: 'disabled',
      category_ids: [chat_categories['くらし・手続き'].id]
    save_chat_intent node_id: node.id, name: '引越しの手続きについて', phrase: %w(引越しの手続きについて 引っ越し 引越し 転居 転入 転出 引越し手続き 引っ越し手続き),
      response: '<p>お引越しなどで住所に変更があったときや世帯に変更があったときは、14日以内に異動の届出が必要です。</p>
    <ul>
      <li><a href="/docs/tenkyo.html">転居届</a></li>
      <li><a href="/docs/page12.html">転入届</a></li>
      <li><a href="/docs/page11.html">転出届</a></li>
    </ul>',
      question: 'enabled', site_search: 'enabled',
      category_ids: [chat_categories['くらし・手続き'].id],
      link: (
        %w(/docs/tenkyo.html /docs/page12.html /docs/page11.html).collect do |url|
          Addressable::URI.join(@site.full_url, url).to_s
        end
      )
    save_chat_intent node_id: node.id, name: '住民票について', phrase: %w(住民票 住民票について),
      response: '<p>住民票については<a href="/kurashi/koseki/jyumin/">住民登録</a>のページをご覧ください。</p>',
      question: 'enabled', site_search: 'enabled',
      category_ids: [chat_categories['くらし・手続き'].id],
      link: Addressable::URI.join(@site.full_url, '/kurashi/koseki/jyumin/').to_s
    save_chat_intent node_id: node.id, name: '印鑑登録について', phrase: %w(印鑑登録について 印鑑登録 印鑑 実印),
      response: '<p>印鑑登録については<a href="/kurashi/koseki/inkan/">印鑑登録</a>のページをご覧ください。</p>',
      question: 'enabled', site_search: 'enabled',
      category_ids: [chat_categories['くらし・手続き'].id],
      link: Addressable::URI.join(@site.full_url, '/kurashi/koseki/inkan/').to_s
    save_chat_intent node_id: node.id, name: 'マイナンバーについて', phrase: %w(マイナンバーについて),
      response: '<p>マイナンバーについては<a href="/kurashi/koseki/koseki/">戸籍</a>のページをご覧ください。</p>',
      question: 'enabled', site_search: 'enabled',
      category_ids: [chat_categories['くらし・手続き'].id],
      link: Addressable::URI.join(@site.full_url, '/kurashi/koseki/koseki/').to_s
    save_chat_intent node_id: node.id, name: '子育てについて', phrase: %w(子育てについて),
      suggest: %w(子育て支援について 検診・予防接種について 保育園・幼稚園について),
      question: 'disabled', site_search: 'disabled',
      category_ids: [chat_categories['子育て・教育'].id]
    save_chat_intent node_id: node.id, name: '子育て支援について', phrase: %w(子育て支援 子育て支援制度 子育て支援について),
      response: '<p>子育て支援については<a href="/kosodate/shien/">子育て支援</a>のページをご覧ください。</p>',
      question: 'enabled', site_search: 'enabled',
      category_ids: [chat_categories['子育て・教育'].id],
      link: Addressable::URI.join(@site.full_url, '/kosodate/shien/').to_s
    save_chat_intent node_id: node.id, name: '検診・予防接種について', phrase: %w(検診 予防接種 定期検診 検診・予防接種について),
      response: '<p>検診・予防接種については<a href="/kosodate/kenko/">母子の健康・予防接種</a>をご覧ください。</p>',
      question: 'enabled', site_search: 'enabled',
      category_ids: [chat_categories['子育て・教育'].id],
      link: Addressable::URI.join(@site.full_url, '/kosodate/kenko/').to_s
    save_chat_intent node_id: node.id, name: '保育園・幼稚園について',
      phrase: %w(保育園 保育所 認定こども園 認可外保育施設 一時保育・託児サービス 幼稚園 保育園・幼稚園について),
      response: '<p>保育園・幼稚園については<a href="/kosodate/hoikuen/">保育園・幼稚園</a>のページをご覧ください。</p>',
      question: 'enabled', site_search: 'enabled',
      category_ids: [chat_categories['子育て・教育'].id],
      link: Addressable::URI.join(@site.full_url, '/kosodate/hoikuen/').to_s
    save_chat_intent node_id: node.id, name: '税金について', phrase: %w(税金について),
      suggest: %w(市民税について 固定資産税について 軽自動車税について),
      question: 'disabled', site_search: 'disabled',
      category_ids: [chat_categories['くらし・手続き'].id]
    save_chat_intent node_id: node.id, name: '市民税について', phrase: %w(市民税 市民税について),
      response: '<p>市民税については<a href="/kurashi/zeikin/shimin/">市民税</a>のページをご覧ください。</p>',
      question: 'enabled', site_search: 'enabled',
      category_ids: [chat_categories['くらし・手続き'].id],
      link: Addressable::URI.join(@site.full_url, '/kurashi/zeikin/shimin/').to_s
    save_chat_intent node_id: node.id, name: '固定資産税について', phrase: %w(固定資産税について),
      response: '<p>固定資産税については<a href="/kurashi/zeikin/kotei/">固定資産税</a>のページをご覧ください。</p>',
      question: 'enabled', site_search: 'enabled',
      category_ids: [chat_categories['くらし・手続き'].id],
      link: Addressable::URI.join(@site.full_url, '/kurashi/zeikin/kotei/').to_s
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
end

# rubocop:disable Naming/ConstantName
if @site
  installer.new(site: @site).call
else
  Chat::DbInstaller = installer
end
# rubocop:enable Naming/ConstantName
