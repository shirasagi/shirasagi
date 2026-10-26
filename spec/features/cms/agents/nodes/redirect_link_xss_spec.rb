require 'spec_helper'

describe "cms/pages", type: :feature, dbscope: :example, js: true do
  let!(:site) do
    site = cms_site
    site.update!(redirect_link_state: "enabled")
    site
  end
  let!(:user) { cms_user }
  let!(:layout) { create_cms_layout cur_site: site }
  let!(:node) { create :cms_node_page, cur_site: site, layout: layout }
  let!(:page1) do
    page = create(:cms_page, cur_site: site, cur_node: node, layout: layout)
    redirect_link = "javascript:window.xss=1"
    page.set(redirect_link: redirect_link)
    page
  end

  it do
    visit node.full_url
    wait_for_js_ready
    click_on page1.name
    wait_for_js_ready
    expect(page.evaluate_script("window.xss")).to be_blank
  end
end
