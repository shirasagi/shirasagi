require 'spec_helper'

describe Rss::Agents::Pages::PageController, type: :request, dbscope: :example do
  let!(:site) { cms_site }
  let!(:user) { cms_user }
  let!(:layout) { create_cms_layout cur_site: site }
  let!(:node) { create :rss_node_page, cur_site: site, layout: layout }
  let!(:page1) do
    create(:rss_page, cur_site: site, cur_node: node, layout: layout, rss_link: "/#{unique_id}.pdf")
  end

  before do
    Fs.rm_rf node.path
    Fs.rm_rf page1.path
  end

  it do
    expect(File.exist?(page1.path)).to be_falsey

    full_url = Addressable::URI.join(site.full_root_url, page1.filename).to_s
    get full_url
    expect(response.status).to eq 302
    expect(response.location).to eq Addressable::URI.join(site.full_root_url, page1.rss_link).to_s
  end
end
