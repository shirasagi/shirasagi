require 'spec_helper'

describe Sys::SiteImportJob, dbscope: :example do
  let!(:source_site) { create :cms_site_unique }
  let!(:node) { create :article_node_page, cur_site: source_site }
  let!(:part) { create :article_part_page, cur_site: source_site, cur_node: node }

  let(:form1_column1_value1) { unique_id * 2 }
  let(:form2_column1_value1) { unique_id * 2 }

  let(:form1_condition_kind) { %w(any_of start_with end_with).sample }
  let(:form1_condition_values) { [ form1_column1_value1 ] }
  let(:form2_condition_kind) { %w(any_of start_with end_with).sample }
  let(:form2_condition_values) { [ form2_column1_value1 ] }

  let!(:form1) do
    create(:cms_form, name: unique_id, cur_site: source_site, state: "public", sub_type: "static")
  end
  let!(:form1_column1) do
    create(:cms_column_text_field, name: unique_id, cur_site: source_site, cur_form: form1,
      order: 1, required: "optional", input_type: 'text')
  end
  let!(:form2) do
    create(:cms_form, name: unique_id, cur_site: source_site, state: "public", sub_type: "static")
  end
  let!(:form2_column1) do
    create(:cms_column_text_field, name: unique_id, cur_site: source_site, cur_form: form2,
      order: 1, required: "optional", input_type: 'text')
  end
  let(:condition_forms) do
    [
      {
        form_id: form1.id,
        filters: [
          { column_id: form1_column1.id, condition_kind: form1_condition_kind, condition_values: form1_condition_values }
        ]
      },
      {
        form_id: form2.id,
        filters: [
          { column_id: form2_column1.id, condition_kind: form2_condition_kind, condition_values: form2_condition_values }
        ]
      }
    ]
  end

  before do
    node.condition_forms = condition_forms
    node.save!

    part.condition_forms = condition_forms
    part.save!
  end

  let!(:file_path) do
    save_export_root = Sys::SiteExportJob.export_root
    Sys::SiteExportJob.export_root = tmpdir

    begin
      job = ::Sys::SiteExportJob.new
      job.bind("site_id" => source_site.id).perform
      output_zip = job.instance_variable_get(:@output_zip)

      output_zip
    ensure
      Sys::SiteExportJob.export_root = save_export_root
    end
  end

  describe "#perform" do
    let!(:destination_site) { create :cms_site_unique }

    let(:dest_node) { Cms::Node.site(destination_site).where(filename: node.filename).first }
    let(:dest_part) { Cms::Part.site(destination_site).where(filename: part.filename).first }
    let(:dest_form1) { Cms::Form.site(destination_site).where(name: form1.name).first }
    let(:dest_form2) { Cms::Form.site(destination_site).where(name: form2.name).first }
    let(:dest_form1_column1) { dest_form1.columns.where(name: form1_column1.name).first }
    let(:dest_form2_column1) { dest_form2.columns.where(name: form2_column1.name).first }
    let(:dest_condition_forms) do
      [
        {
          form_id: dest_form1.id,
          filters: [
            { column_id: dest_form1_column1.id, condition_kind: form1_condition_kind, condition_values: form1_condition_values }
          ]
        },
        {
          form_id: dest_form2.id,
          filters: [
            { column_id: dest_form2_column1.id, condition_kind: form2_condition_kind, condition_values: form2_condition_values }
          ]
        }
      ]
    end

    it do
      job = ::Sys::SiteImportJob.new
      job.bind("site_id" => destination_site.id).perform(file_path)

      dest_node
      dest_part
      dest_form1
      dest_form2
      dest_form1_column1
      dest_form2_column1
      dest_condition_forms

      expect(dest_node).to be_present
      expect(dest_part).to be_present

      expect(dest_form1).to be_present
      expect(dest_form1.columns.count).to eq form1.columns.count
      expect(dest_form2).to be_present
      expect(dest_form2.columns.count).to eq form2.columns.count
      expect(dest_form1_column1).to be_present
      expect(dest_form2_column1).to be_present

      expect(dest_node.condition_forms.to_a).to eq dest_condition_forms
      expect(dest_part.condition_forms.to_a).to eq dest_condition_forms
    end
  end
end
