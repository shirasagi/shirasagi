require 'spec_helper'

describe Cms::PageExporter, dbscope: :example do
  let(:now) { Time.zone.now.change(usec: 0) }
  let(:today) { Time.zone.today }
  let!(:site) { cms_site }
  let!(:user) { cms_user }
  let!(:form) { create :cms_form, cur_site: site, state: 'public', sub_type: 'static' }
  let!(:node) { create :article_node_page, cur_site: site, st_form_ids: [ form.id ] }

  describe "#enum_csv" do
    context "select_page and map" do
      let!(:column1) do
        create(:cms_column_select_page, cur_site: site, cur_form: form, required: "optional", node_ids: [ node.id ])
      end
      let(:column1_alignment) { %w(flow left center right).sample }
      let!(:node2) { create :article_node_page, cur_site: site }
      let(:column1_page) { create :article_page, cur_site: site, cur_node: node2, state: %w(public closed).sample }
      let!(:page1) do
        create(
          :article_page, cur_site: site, cur_node: node, form: form,
          column_values: [
            column1.value_type.new(
              column: column1, name: column1.name, alignment: column1_alignment, page: column1_page)
          ],
          map_reference_method: "page", map_reference_column_name: column1.name
        )
      end

      it do
        exporter = described_class.new(mode: "article", site: site, criteria: Article::Page.all.site(site).node(node), form: form)
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
            [ form.name, column1.name, column1.value_type.t(:page) ].join("/").tap do |header|
              expect(csv_row[header]).to eq "#{column1_page.name} (#{column1_page.id})"
            end

            expect(csv_row[Article::Page.t(:map_reference_method)]).to eq page1.label(:map_reference_method)
            expect(csv_row[Article::Page.t(:map_reference_column_name)]).to eq column1.name
          end
        end
      end
    end
  end
end
