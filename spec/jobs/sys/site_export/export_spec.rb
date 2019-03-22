require 'spec_helper'
require 'rake'

describe Sys::SiteExportJob, dbscope: :example do
  let(:site) { cms_site }

  around do |example|
    tmpdir = ::Dir.mktmpdir(unique_id, "#{Rails.root}/tmp")
    ::Dir.mkdir_p(tmpdir) if !::Dir.exists?(tmpdir)

    Sys::SiteExportJob.export_root = tmpdir

    example.run

    FileUtils.rm_rf(tmpdir)
  end

  def execute
    job = Sys::SiteExportJob.new
    task = OpenStruct.new(source_site_id: site.id)
    def task.log(msg)
      puts(msg)
    end
    job.task = task
    job.perform
    job.instance_variable_get(:@output_zip)
  end

  context 'site export' do
    it do
      zip_path = execute
      Zip::File.open(zip_path) do |zip|
        # "version.json" is not json format
        expect(zip.read(zip.get_entry("version.json"))).not_to be_nil
        expect(JSON.parse(zip.read(zip.get_entry("cms_site.json")))).not_to be_nil
        expect(JSON.parse(zip.read(zip.get_entry("cms_groups.json")))).not_to be_nil
        expect(JSON.parse(zip.read(zip.get_entry("cms_users.json")))).not_to be_nil
        expect(JSON.parse(zip.read(zip.get_entry("cms_roles.json")))).not_to be_nil
        expect(JSON.parse(zip.read(zip.get_entry("cms_forms.json")))).not_to be_nil
        expect(JSON.parse(zip.read(zip.get_entry("cms_columns.json")))).not_to be_nil
        expect(JSON.parse(zip.read(zip.get_entry("cms_layouts.json")))).not_to be_nil
        expect(JSON.parse(zip.read(zip.get_entry("cms_body_layouts.json")))).not_to be_nil
        expect(JSON.parse(zip.read(zip.get_entry("cms_nodes.json")))).not_to be_nil
        expect(JSON.parse(zip.read(zip.get_entry("cms_parts.json")))).not_to be_nil
        expect(JSON.parse(zip.read(zip.get_entry("cms_pages.json")))).not_to be_nil
        expect(JSON.parse(zip.read(zip.get_entry("cms_page_searches.json")))).not_to be_nil
        expect(JSON.parse(zip.read(zip.get_entry("cms_notices.json")))).not_to be_nil
        expect(JSON.parse(zip.read(zip.get_entry("cms_editor_templates.json")))).not_to be_nil
        expect(JSON.parse(zip.read(zip.get_entry("cms_theme_templates.json")))).not_to be_nil
        expect(JSON.parse(zip.read(zip.get_entry("cms_source_cleaner_templates.json")))).not_to be_nil
        expect(JSON.parse(zip.read(zip.get_entry("cms_loop_settings.json")))).not_to be_nil
        expect(JSON.parse(zip.read(zip.get_entry("ezine_columns.json")))).not_to be_nil
        expect(JSON.parse(zip.read(zip.get_entry("inquiry_columns.json")))).not_to be_nil
        expect(JSON.parse(zip.read(zip.get_entry("kana_dictionaries.json")))).not_to be_nil
        expect(JSON.parse(zip.read(zip.get_entry("opendata_dataset_groups.json")))).not_to be_nil
        expect(JSON.parse(zip.read(zip.get_entry("opendata_licenses.json")))).not_to be_nil
        expect(JSON.parse(zip.read(zip.get_entry("ss_files.json")))).not_to be_nil
      end
    end
  end

  context 'with forms and columns' do
    let!(:form1) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'static') }
    let!(:form2) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'entry') }
    let!(:form1_column1) do
      create(:cms_column_text_field, cur_site: site, cur_form: form1, input_type: 'text')
    end
    let!(:form2_column1) do
      create(:cms_column_text_field, cur_site: site, cur_form: form2, input_type: 'text')
    end

    it do
      zip_path = execute
      Zip::File.open(zip_path) do |zip|
        JSON.parse(zip.read(zip.get_entry("cms_forms.json"))).tap do |cms_forms|
          expect(cms_forms).to be_a(Array)
          expect(cms_forms.length).to eq 2
          expect(cms_forms[0]["name"]).to eq form1.name
          expect(cms_forms[0]["order"]).to eq form1.order
          expect(cms_forms[0]["state"]).to eq form1.state
          expect(cms_forms[0]["sub_type"]).to eq form1.sub_type
          expect(cms_forms[0].key?("_type")).to be_falsey

          expect(cms_forms[1]["name"]).to eq form2.name
          expect(cms_forms[1]["order"]).to eq form2.order
          expect(cms_forms[1]["state"]).to eq form2.state
          expect(cms_forms[1]["sub_type"]).to eq form2.sub_type
          expect(cms_forms[1].key?("_type")).to be_falsey
        end
        JSON.parse(zip.read(zip.get_entry("cms_columns.json"))).tap do |cms_columns|
          expect(cms_columns).to be_a(Array)
          expect(cms_columns.length).to eq 2

          expect(cms_columns[0]["_type"]).to eq form1_column1.class.name
          expect(cms_columns[0]["name"]).to eq form1_column1.name
          expect(cms_columns[0]["order"]).to eq form1_column1.order
          expect(cms_columns[0]["input_type"]).to eq form1_column1.input_type
          expect(cms_columns[0]["form_id"]).to eq form1.id

          expect(cms_columns[1]["_type"]).to eq form2_column1.class.name
          expect(cms_columns[1]["name"]).to eq form2_column1.name
          expect(cms_columns[1]["order"]).to eq form2_column1.order
          expect(cms_columns[1]["input_type"]).to eq form2_column1.input_type
          expect(cms_columns[1]["form_id"]).to eq form2.id
        end
      end
    end
  end
end
