require 'spec_helper'

describe Cms::AllContent, type: :model, dbscope: :example do
  describe ".csv" do
    let(:csv) { described_class.csv }

    describe "header line" do
      let(:header) { csv.split("\n")[0].split(",") }
      it { expect(header[0]).to eq(I18n.t("all_content.url")) }
      it { expect(header[1]).to eq(I18n.t("all_content.group_ids")) }
      it { expect(header[15]).to eq(I18n.t("all_content.have_files")) }
    end

    describe "contents" do
      before do
        @page = create :cms_page
        @node = create :cms_node
      end

      let(:line1) { csv.split("\n")[1].split(",") }
      let(:line2) { csv.split("\n")[2].split(",") }

      it { expect(line1[0]).to eq @page.full_url }
      it { expect(line2[0]).to eq @node.full_url }
    end
  end
end
