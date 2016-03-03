require 'spec_helper'

describe "cms_node_import", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create_once :cms_node_import_node, name: "import" }
  let(:index_path) { node_import_path site.id, node }

  it "without login" do
    visit index_path
    expect(current_path).to eq sns_login_path
  end

  it "without auth" do
    login_ss_user
    visit index_path
    expect(status_code).to eq 403
  end

  context "with auth" do
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
        click_button "取り込み"
      end
      expect(status_code).to eq 200

      pages = Cms::ImportPage.all.entries
      nodes = Cms::Node::ImportNode.all.entries
      expect(pages.map(&:name)).to eq %w(page.html index.html)
      expect(nodes.map(&:name)).to eq %w(import article css img)

      pages.each do |page|
        expect(page.html.present?).to eq true
        page.html.scan(/(href|src)="\/(.+?)"/) do
          path = $2
          expect(path =~ /#{node.filename}\//).to eq 0
        end
      end
    end
  end
end
