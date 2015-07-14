require 'spec_helper'

describe "cms_import" do
  subject(:site) { cms_site }
  subject(:index_path) { cms_import_path site.host }

  it "without login" do
    visit index_path
    expect(current_path).to eq sns_login_path
  end

  it "without auth" do
    login_ss_user
    visit index_path
    expect(status_code).to eq 403
  end

  context "with auth", js: true do
    before { login_cms_user }

    it "#index" do
      visit index_path
      expect(status_code).to eq 200
      expect(current_path).to eq index_path
    end

    it "#import" do
      visit index_path
      within "form#item-form" do
        attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/cms/import/site.zip"
        wait_for_ajax
        click_button "取り込み"
      end
      expect(status_code).to eq 200

      pages = Cms::ImportPage.all.entries
      nodes = Cms::Node::ImportNode.all.entries
      expect(pages.map(&:name)).to eq %w(1.html index.html)
      expect(nodes.map(&:name)).to eq %w(site article css img)
    end
  end
end
