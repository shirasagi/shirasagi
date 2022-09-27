require 'spec_helper'

describe Cms::AllContent, type: :model, dbscope: :example do
  let(:site) { cms_site }

  describe "#enum_csv" do
    let(:csv) { described_class.new(site: site).enum_csv(encoding: 'UTF-8') }

    describe "header line" do
      let(:header) { csv.to_a[0].split(",") }
      it { expect(header[0]).to eq(SS::Csv::UTF8_BOM + I18n.t("all_content.page_id")) }
      it { expect(header[1]).to eq(I18n.t("all_content.node_id")) }
      it { expect(header).to include(I18n.t("all_content.updated")) }
    end

    describe "contents" do
      before do
        @page = create :cms_page
        @node = create :cms_node
      end

      let(:line1) { csv.to_a[1].split(",") }
      let(:line2) { csv.to_a[2].split(",") }

      it { expect(line1[9]).to eq @page.full_url }
      it { expect(line2[9]).to eq @node.full_url }
    end
  end
end
