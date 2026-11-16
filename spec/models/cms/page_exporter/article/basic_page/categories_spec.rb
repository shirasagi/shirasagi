require 'spec_helper'

describe Cms::PageExporter, dbscope: :example do
  let(:now) { Time.zone.now.change(usec: 0) }
  let(:today) { Time.zone.today }
  let!(:site) { cms_site }
  let!(:user) { cms_user }
  let!(:node) { create :article_node_page, cur_site: site }

  describe "#enum_csv" do
    context "categories" do
      let!(:cate1) { create(:category_node_page, cur_site: site) }
      let!(:page1) do
        create(:article_page, cur_site: site, cur_node: node, category_ids: [ cate1.id ])
      end

      it do
        exporter = described_class.new(mode: "article", site: site, criteria: Article::Page.all, form: nil)
        io = StringIO.new(exporter.enum_csv(encoding: "UTF-8").to_a.join)
        SS::Csv.open(io) do |csv|
          csv_table = csv.read
          expect(csv_table.length).to eq 1
          csv_table[0].tap do |csv_row|
            expect(csv_row[Article::Page.t(:categories)]).to eq "#{cate1.name} (#{cate1.filename})"
          end
        end
      end
    end
  end
end
