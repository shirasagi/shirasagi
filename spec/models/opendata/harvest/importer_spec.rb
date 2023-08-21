require 'spec_helper'

describe Opendata::Harvest::Importer, dbscope: :example do
  let!(:site) { cms_site }
  let!(:node) { create(:opendata_node_dataset, name: "datasets") }
  let!(:node_search) { create_once :opendata_node_search_dataset }
  let!(:dataset) { create(:opendata_dataset, cur_node: node) }

  let!(:license1) { create(:opendata_license, cur_site: site, uid: "cc-by") }
  let!(:license2) { create(:opendata_license, cur_site: site, uid: "cc-by-sa") }

  let!(:cate) { create(:opendata_node_category) }
  let!(:estat_cate) { create(:opendata_node_estat_category) }
  let!(:area) { create(:opendata_node_area) }

  let!(:item) do
    create(:opendata_harvest_importer, cur_node: node,
      default_category_ids: [cate.id],
      default_estat_category_ids: [estat_cate.id],
      default_area_ids: [area.id]
    )
  end

  let(:resouce_url1) { "https://source.example.jp/index.html" }
  let(:resouce_url2) { "https://source.example.jp/sample.csv" }
  let(:resouce_url3) { "https://other.example.jp/index.html" }
  let(:resouce_url4) { "https://other.example.jp/sample.csv" }

  context "harvest importer" do
    it "#api_type_options" do
      expect(item.api_type_options).not_to be_nil
    end
  end

  context "addon harvest importer" do
    it "#get_license_from_uid" do
      expect(item.send(:get_license_from_uid, license1.uid).id).to eq license1.id
      expect(item.send(:get_license_from_uid, license2.uid).id).to eq license2.id
    end

    it "#get_license_from_name" do
      expect(item.send(:get_license_from_name, license1.name).id).to eq license1.id
      expect(item.send(:get_license_from_name, license2.name).id).to eq license2.id
    end

    it "#set_relation_ids" do
      item.send(:set_relation_ids, dataset)
      expect(dataset.category_ids).to include cate.id
      expect(dataset.estat_category_ids).to include estat_cate.id
      expect(dataset.area_ids).to include area.id
    end

    it "#external_resouce?" do
      expect(item.send(:external_resouce?, resouce_url1, "html")).to be_truthy
      expect(item.send(:external_resouce?, resouce_url2, "csv")).to be_falsy
      expect(item.send(:external_resouce?, resouce_url3, "html")).to be_truthy
      expect(item.send(:external_resouce?, resouce_url4, "csv")).to be_truthy
    end
  end
end
