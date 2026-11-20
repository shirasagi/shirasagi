require 'spec_helper'

describe Cms::PageExporter, dbscope: :example do
  let(:now) { Time.zone.now.change(usec: 0) }
  let(:today) { Time.zone.today }
  let!(:site) { cms_site }
  let!(:user) { cms_user }
  let!(:form) { create :cms_form, cur_site: site, state: 'public', sub_type: 'static' }
  let!(:node) { create :article_node_page, cur_site: site, st_form_ids: [ form.id ] }

  describe "#enum_csv" do
    context "headline" do
      let!(:column1) do
        create(:cms_column_headline, cur_site: site, cur_form: form, required: "optional")
      end
      let(:column1_alignment) { %w(flow left center right).sample }
      let(:column1_head) { %w(h1 h2).sample }
      let(:column1_text) { unique_id }
      let!(:page1) do
        create(
          :article_page, cur_site: site, cur_node: node, form: form,
          column_values: [
            column1.value_type.new(
              column: column1, name: column1.name, alignment: column1_alignment,
              head: column1_head, text: column1_text)
          ]
        )
      end

      it do
        exporter = described_class.new(mode: "article", site: site, criteria: Article::Page.all, form: form)
        io = StringIO.new(exporter.enum_csv(encoding: "UTF-8").to_a.join)
        SS::Csv.open(io) do |csv|
          csv_table = csv.read
          expect(csv_table.length).to eq 1
          # puts csv_table.headers.join("\n")
          csv_table[0].tap do |csv_row|
            expect(csv_row[Article::Page.t(:filename)]).to eq page1.basename
            [ form.name, column1.name, column1.value_type.t(:alignment) ].join("/").tap do |header|
              expect(csv_row[header]).to eq I18n.t(column1_alignment, scope: "cms.options.alignment")
            end
            [ form.name, column1.name, column1.value_type.t(:head) ].join("/").tap do |header|
              expect(csv_row[header]).to eq column1_head
            end
            [ form.name, column1.name, column1.value_type.t(:text) ].join("/").tap do |header|
              expect(csv_row[header]).to eq column1_text
            end
          end
        end
      end
    end
  end
end
