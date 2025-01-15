require 'spec_helper'

describe 'cms_agents_addons_file', type: :feature, dbscope: :example, js: true do
  let(:site){ cms_site }
  let!(:node) { create :article_node_page, cur_site: site, cur_user: cms_user }
  let(:name) { "#{unique_id}.png" }
  let!(:file_1) { tmp_ss_file contents: "#{Rails.root}/spec/fixtures/ss/logo.png", user: cms_user, basename: "#{unique_id}.jpg" }
  let!(:file_2) { tmp_ss_file user: cms_user, basename: "#{unique_id}.jpg" }
  let!(:item1) { create :article_page, cur_site: site, cur_user: cms_user, cur_node: node, file_ids: [ file_1.id ] }

  before do
    login_cms_user
    item1.update(contains_urls: [file_1.url])
  end

  context "with article/page" do
    describe "index" do
      it do
        visit edit_path(site: site)
        expect(page).to have_css(".file-view", text: file_1.name)
        expect(page).to have_css(".file-view unused", text: file_2.name)
      end
    end
  end
end
