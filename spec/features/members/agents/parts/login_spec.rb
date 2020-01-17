require 'spec_helper'

describe "member_agents_parts_logins", type: :feature, dbscope: :example, js: true do
  let(:site)   { cms_site }
  let(:layout) { create_cms_layout part }
  let(:node)   { create :cms_node, layout_id: layout.id }
  let(:part)   { create :member_part_login }

  context "public" do
    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    it "#index" do
      visit node.url
      expect(page).to have_no_css(".ss-part")
      expect(page).to have_css(".login")
    end
  end
end
