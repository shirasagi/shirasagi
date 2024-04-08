require 'spec_helper'

describe Chat::Agents::Nodes::BotController, type: :request, dbscope: :example do
  let!(:site) { cms_site }
  let!(:layout) { create :cms_layout, site: site }
  let!(:chat_node) { create :chat_node_bot, cur_site: site, filename: "chatbot", layout: layout }

  before do
    Chat.autoload :DbInstaller, "#{Rails.root}/db/seeds/demo/contents/chat"
    expect do
      Chat::DbInstaller.new(site: site).call
    end.to output.to_stdout
  end

  it do
    params = {
      text: "軽自動車税について",
      click_suggest: true,
      public_path: "#{chat_node.url}index"
    }
    get "#{chat_node.full_url}index.json?#{params.to_query}"
    expect(response.status).to eq 200
    json = JSON.parse(response.body)
    results = json["results"]
    expect(results).to have(1).items
    chat_success = json["chatSuccess"]
    expect(chat_success).to eq "はい"
    chat_retry = json["chatRetry"]
    expect(chat_retry).to eq "いいえ"
    site_search_text = json["siteSearchText"]
    expect(site_search_text).to eq "サイト内検索の結果を開く"
  end
end
