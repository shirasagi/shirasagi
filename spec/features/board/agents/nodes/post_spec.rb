require 'spec_helper'

describe 'board_agents_nodes_anpi_post', type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:layout) { create_cms_layout }
  let(:node) { create :board_node_post, cur_site: site, layout_id: layout.id, deny_url: 'allow' }

  context 'usual case' do
    let!(:item) { create :board_post, cur_site: site, cur_node: node }

    it do
      visit node.full_url

      expect(page).to have_css(".email[href='mailto:#{item.email}']")
      query = { back_to: node.url, ref: item.poster_url }.to_query
      expect(page).to have_css(".url[href='/.mypage/redirect?#{query}']")
    end
  end

  context 'protect from xss vulnerability' do
    let(:http_url) { "http://#{unique_id}.example.jp" }
    let(:https_url) { "https://#{unique_id}.example.jp" }
    let(:mail_to_url) { "mailto:#{unique_id}@example.jp" }
    let(:text) { [ http_url, https_url, mail_to_url ].join("\n") }
    let!(:item) { create :board_post, cur_site: site, cur_node: node, text: text }

    before do
      item.set(email: "javascript:alert('危険な操作');", poster_url: "javascript:alert('危険な操作');")
    end

    it do
      visit node.full_url

      expect(page).to have_css(".body a[href='/.mypage/redirect?ref=#{CGI.escape(http_url)}']")
      expect(page).to have_css(".body a[href='/.mypage/redirect?ref=#{CGI.escape(https_url)}']")
      expect(page).to have_no_css("a[href='#{mail_to_url}']")
      expect(page).to have_no_css("a[href='#{CGI.escape(mail_to_url)}']")
      expect(page).to have_no_css(".email")
      expect(page).to have_no_css(".url")
    end
  end
end
