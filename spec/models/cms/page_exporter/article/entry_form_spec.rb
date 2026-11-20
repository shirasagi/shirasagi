require 'spec_helper'

describe Cms::PageExporter, dbscope: :example do
  let(:now) { Time.zone.now.change(usec: 0) }
  let(:today) { Time.zone.today }
  let!(:site) { cms_site }
  let!(:user) { cms_user }
  let!(:form) { create :cms_form, cur_site: site, state: 'public', sub_type: 'entry' }
  let!(:node) { create :article_node_page, cur_site: site, st_form_ids: [ form.id ] }

  describe "#enum_csv" do
    context "text_field" do
      let!(:column1) do
        create(:cms_column_text_field, cur_site: site, cur_form: form, required: "optional", input_type: 'text')
      end
      let(:column1_alignment1) { %w(flow left center right).sample }
      let(:column1_value1) { unique_id }
      let(:column1_alignment2) { %w(flow left center right).sample }
      let(:column1_value2) { unique_id }
      let!(:page1) do
        create(
          :article_page, cur_site: site, cur_node: node, form: form,
          column_values: [
            column1.value_type.new(
              column: column1, name: column1.name, alignment: column1_alignment1, value: column1_value1),
            column1.value_type.new(
              column: column1, name: column1.name, alignment: column1_alignment2, value: column1_value2)
          ]
        )
      end

      it do
        exporter = described_class.new(mode: "article", site: site, criteria: Article::Page.all, form: form)
        io = StringIO.new(exporter.enum_csv(encoding: "UTF-8").to_a.join)
        SS::Csv.open(io) do |csv|
          csv_table = csv.read
          expect(csv_table.length).to eq 1
          # 本文は出力されない
          expect(csv_table.headers).not_to include(Article::Page.t(:html))
          # ブロック型入力の場合、定型フォームの項目はCSVに出力されない
          expect(csv_table.headers.none? { _1.start_with?(form.name) }).to be_truthy
        end
      end
    end
  end
end
