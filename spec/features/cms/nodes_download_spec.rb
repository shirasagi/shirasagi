require 'spec_helper'

describe "cms_nodes", type: :feature, dbscope: :example do
  subject(:site) { cms_site }
  subject(:download_path) { download_cms_nodes_path site.id }
  subject(:import_path) { import_cms_nodes_path site.id }

  let!(:item1) { create :cms_node, filename: "parent1" }
  let!(:item2) { create :cms_node, filename: "parent2" }
  let!(:item3) { create :cms_node, cur_node: item1 }
  let!(:item4) { create :cms_node, cur_node: item1 }
  let!(:item5) { create :cms_node, cur_node: item2 }
  let!(:item6) { create :cms_node, cur_node: item2 }

  context "download" do
    before { login_cms_user }

    it "#download" do
      visit download_path

      click_on I18n.t("ss.buttons.download")
      csv = SS::ChunkReader.new(page.html).to_a.join
      csv = csv.force_encoding("UTF-8").delete_prefix(SS::Csv::UTF8_BOM)
      csv = ::CSV.parse(csv, headers: true)

      expect(csv.size).to eq 2

      expect(csv[0][I18n.t("cms.node_columns.filename")]).to eq item1.basename
      expect(csv[1][I18n.t("cms.node_columns.filename")]).to eq item2.basename
    end
  end

  context "import", js: true do
    let(:item) { Cms::Node.last }

    before { login_cms_user }

    it "#import" do
      visit import_path

      perform_enqueued_jobs do
        within "form#task-form" do
          attach_file "item[file]", "#{Rails.root}/spec/fixtures/cms/node/import/ads.csv"
          page.accept_confirm do
            click_on I18n.t("ss.links.import")
          end
        end
        wait_for_notice I18n.t("ss.notice.started_import")
      end
      expect(Cms::Node.count).to eq 7
      expect(item.filename).to eq "ad"
      expect(item.parent).to eq false
    end
  end
end
