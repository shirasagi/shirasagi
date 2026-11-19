require 'spec_helper'

describe Cms::PageExporter, dbscope: :example do
  let(:now) { Time.zone.now.change(usec: 0) }
  let(:today) { Time.zone.today }
  let!(:site) { cms_site }
  let!(:user) { cms_user }
  let!(:node) { create :article_node_page, cur_site: site }

  describe "#enum_csv" do
    context "facility" do
      let!(:facility_node) { create :facility_node_node, cur_site: site }
      let!(:facility_page1) { create :facility_node_page, cur_site: site, cur_node: facility_node }
      let!(:facility_page2) { create :facility_node_page, cur_site: site, cur_node: facility_node }
      let!(:page1) do
        create(:article_page, cur_site: site, cur_node: node, facility_ids: [ facility_page1.id, facility_page2.id ])
      end

      it do
        exporter = described_class.new(mode: "article", site: site, criteria: Article::Page.all, form: nil)
        io = StringIO.new(exporter.enum_csv(encoding: "UTF-8").to_a.join)
        SS::Csv.open(io) do |csv|
          csv_table = csv.read
          expect(csv_table.length).to eq 1
          csv_table[0].tap do |csv_row|
            exported = [
              "#{facility_page1.name} (#{facility_page1.filename})",
              "#{facility_page2.name} (#{facility_page2.filename})"
            ].join("\n")
            expect(csv_row[Article::Page.t(:facilities)]).to eq exported
          end
        end
      end
    end
  end
end
