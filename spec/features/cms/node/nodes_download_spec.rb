

require 'spec_helper'

describe "cms_node_nodes", type: :feature, js: :true, dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create :cms_node }
  let(:item) { create :cms_node, filename: "#{node.filename}/name" }
  let(:index_path)  { node_nodes_path site.id, node }
  let(:download_path)   { "#{index_path}/download" }
  let(:import_path)   { "#{index_path}/import" }

  context "with auth" do
    before { login_cms_user }

    it "#download" do
      visit download_path
    
      find('input[value="ダウンロード"]').click
      wait_for_ajax
    
      csv = ::CSV.read(downloads.first, headers: true, encoding: 'UTF-8')
      row = csv[0]
      expect(row).to be_nil
    end

    it "import" do 
      visit import_path

      within "form#task-form" do
        attach_file "item[file]", "#{Rails.root}/spec/fixtures/cms/node/import/ads.csv" 
        page.accept_confirm do
          click_on I18n.t("ss.links.import")
        end
      end
      expect(page).to have_content I18n.t("ss.notice.started_import")
    end

  end
end
