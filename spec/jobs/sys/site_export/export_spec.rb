require 'spec_helper'
require 'rake'

describe Sys::SiteExportJob, dbscope: :example do
  let(:site) { cms_site }

  before do
    SS::Sequence.create(_id: "cms_body_layouts_id", value: rand(0..999) * 1_000_000)
    SS::Sequence.create(_id: "cms_editor_templates_id", value: rand(0..999) * 1_000_000)
    SS::Sequence.create(_id: "cms_forms_id", value: rand(0..999) * 1_000_000)
    SS::Sequence.create(_id: "cms_layouts_id", value: rand(0..999) * 1_000_000)
    SS::Sequence.create(_id: "cms_loop_settings_id", value: rand(0..999) * 1_000_000)
    SS::Sequence.create(_id: "cms_members_id", value: rand(0..999) * 1_000_000)
    SS::Sequence.create(_id: "cms_nodes_id", value: rand(0..999) * 1_000_000)
    SS::Sequence.create(_id: "cms_page_searches_id", value: rand(0..999) * 1_000_000)
    SS::Sequence.create(_id: "cms_pages_id", value: rand(0..999) * 1_000_000)
    SS::Sequence.create(_id: "cms_parts_id", value: rand(0..999) * 1_000_000)
    SS::Sequence.create(_id: "cms_roles_id", value: rand(0..999) * 1_000_000)
    SS::Sequence.create(_id: "cms_source_cleaner_templates_id", value: rand(0..999) * 1_000_000)
    SS::Sequence.create(_id: "cms_theme_templates_id", value: rand(0..999) * 1_000_000)
    SS::Sequence.create(_id: "cms_word_dictionaries_id", value: rand(0..999) * 1_000_000)
    SS::Sequence.create(_id: "ezine_columns_id", value: rand(0..999) * 1_000_000)
    SS::Sequence.create(_id: "inquiry_answers_id", value: rand(0..999) * 1_000_000)
    SS::Sequence.create(_id: "inquiry_columns_id", value: rand(0..999) * 1_000_000)
    SS::Sequence.create(_id: "ss_files_id", value: rand(0..999) * 1_000_000)
    SS::Sequence.create(_id: "ss_groups_id", value: rand(0..999) * 1_000_000)
    SS::Sequence.create(_id: "ss_max_file_sizes_id", value: rand(0..999) * 1_000_000)
    SS::Sequence.create(_id: "ss_sites_id", value: rand(0..999) * 1_000_000)
    SS::Sequence.create(_id: "ss_users_id", value: rand(0..999) * 1_000_000)
    SS::Sequence.create(_id: "sys_roles_id", value: rand(0..999) * 1_000_000)
    SS::Sequence.create(_id: "workflow_routes_id", value: rand(0..999) * 1_000_000)
  end

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

  context 'with pages' do
    let!(:form1) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'static') }
    let!(:form2) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'entry') }
    let!(:form1_column1) do
      create(:cms_column_text_field, cur_site: site, cur_form: form1, input_type: 'text', order: 10)
    end
    let!(:form1_column2) do
      create(:cms_column_file_upload, cur_site: site, cur_form: form1, file_type: 'image', order: 20)
    end
    let!(:form1_column3) do
      create(:cms_column_free, cur_site: site, cur_form: form1, order: 30)
    end
    let!(:form2_column1) do
      create(:cms_column_text_field, cur_site: site, cur_form: form2, input_type: 'text', order: 10)
    end
    let!(:form2_column2) do
      create(:cms_column_file_upload, cur_site: site, cur_form: form2, file_type: 'image', order: 20)
    end
    let!(:form2_column3) do
      create(:cms_column_free, cur_site: site, cur_form: form2, order: 30)
    end

    let!(:node) { create :article_node_page, cur_site: site }
    let(:page1_file1) do
      tmp_ss_file(contents: "#{Rails.root}/spec/fixtures/ss/logo.png", site: site, user: cms_user, model: 'ss/temp_file')
    end
    let(:page1_file1_img_tag) { "<img src=\"#{page1_file1.url}\">" }
    let!(:page1) do
      create(
        :article_page, cur_site: site, cur_node: node, basename: "#{unique_id}.html",
        html: unique_id * 5 + "\n" + page1_file1_img_tag, file_ids: [ page1_file1.id ]
      )
    end

    let(:page2_file1) do
      tmp_ss_file(contents: "#{Rails.root}/spec/fixtures/ss/logo.png", site: site, user: cms_user, model: 'ss/temp_file')
    end
    let(:page2_file2) do
      tmp_ss_file(contents: "#{Rails.root}/spec/fixtures/ss/logo.png", site: site, user: cms_user, model: 'ss/temp_file')
    end
    let(:page2_file1_img_tag) { "<img src=\"#{page2_file1.url}\">" }
    let(:page2_file2_img_tag) { "<img src=\"#{page2_file2.url}\">" }
    let!(:page2) do
      create(
        :article_page, cur_site: site, cur_node: node, basename: "#{unique_id}.html",
        form: form1, column_values: [
          form1_column1.value_type.new(column: form1_column1, value: unique_id * 6),
          form1_column2.value_type.new(column: form1_column2, file_id: page2_file1.id),
          form1_column3.value_type.new(
            column: form1_column3, value: unique_id * 5 + "\n" + page2_file2_img_tag, file_ids: [ page2_file2.id ]
          )
        ]
      )
    end

    let(:page3_file1) do
      tmp_ss_file(contents: "#{Rails.root}/spec/fixtures/ss/logo.png", site: site, user: cms_user, model: 'ss/temp_file')
    end
    let(:page3_file2) do
      tmp_ss_file(contents: "#{Rails.root}/spec/fixtures/ss/logo.png", site: site, user: cms_user, model: 'ss/temp_file')
    end
    let(:page3_file3) do
      tmp_ss_file(contents: "#{Rails.root}/spec/fixtures/ss/logo.png", site: site, user: cms_user, model: 'ss/temp_file')
    end
    let(:page3_file4) do
      tmp_ss_file(contents: "#{Rails.root}/spec/fixtures/ss/logo.png", site: site, user: cms_user, model: 'ss/temp_file')
    end
    let(:page3_file1_img_tag) { "<img src=\"#{page3_file1.url}\">" }
    let(:page3_file2_img_tag) { "<img src=\"#{page3_file2.url}\">" }
    let(:page3_file3_img_tag) { "<img src=\"#{page3_file3.url}\">" }
    let(:page3_file4_img_tag) { "<img src=\"#{page3_file4.url}\">" }
    let!(:page3) do
      create(
        :article_page, cur_site: site, cur_node: node, basename: "#{unique_id}.html",
        form: form2,
        column_values: [
          form2_column1.value_type.new(column: form2_column1, order: 0, value: unique_id * 6),
          form2_column1.value_type.new(column: form2_column1, order: 1, value: unique_id * 6),
          form2_column2.value_type.new(column: form2_column2, order: 2, file_id: page3_file1.id),
          form2_column2.value_type.new(column: form2_column2, order: 3, file_id: page3_file2.id),
          form2_column3.value_type.new(
            column: form2_column3, order: 4, value: unique_id * 5 + "\n" + page3_file3_img_tag, file_ids: [ page3_file3.id ]
          ),
          form2_column3.value_type.new(
            column: form2_column3, order: 5, value: unique_id * 5 + "\n" + page3_file4_img_tag, file_ids: [ page3_file4.id ]
          )
        ]
      )
    end

    before do
      page1_file1.reload
      page2_file1.reload
      page2_file2.reload
      page3_file1.reload
      page3_file2.reload
      page3_file3.reload
      page3_file4.reload
    end

    it do
      zip_path = execute
      # ::FileUtils.cp(zip_path, "#{Rails.root}/spec/fixtures/sys/site-exports-1.zip")
      Zip::File.open(zip_path) do |zip|
        JSON.parse(zip.read(zip.get_entry("cms_pages.json"))).tap do |cms_pages|
          expect(cms_pages).to be_a(Array)
          expect(cms_pages.length).to eq 3

          cms_pages[0].tap do |cms_page|
            expect(cms_page["name"]).to eq page1.name
            expect(cms_page["filename"]).to eq page1.filename
            expect(cms_page["html"]).to eq page1.html
            expect(cms_page["file_ids"]).to eq page1.file_ids
          end

          cms_pages[1].tap do |cms_page|
            expect(cms_page["name"]).to eq page2.name
            expect(cms_page["filename"]).to eq page2.filename
            expect(cms_page["column_values"]).to be_a(Array)
            expect(cms_page["column_values"][0]["_type"]).to eq page2.column_values[0].class.name
            expect(cms_page["column_values"][0]["column_id"]).to eq("$oid" => page2.column_values[0].column.id.to_s)
            expect(cms_page["column_values"][0]["name"]).to eq page2.column_values[0].name
            expect(cms_page["column_values"][0]["order"]).to eq page2.column_values[0].order
            expect(cms_page["column_values"][0]["value"]).to eq page2.column_values[0].value
            expect(cms_page["column_values"][1]["_type"]).to eq page2.column_values[1].class.name
            expect(cms_page["column_values"][1]["column_id"]).to eq("$oid" => page2.column_values[1].column.id.to_s)
            expect(cms_page["column_values"][1]["name"]).to eq page2.column_values[1].name
            expect(cms_page["column_values"][1]["order"]).to eq page2.column_values[1].order
            expect(cms_page["column_values"][1]["file_id"]).to eq page2.column_values[1].file_id
            expect(cms_page["column_values"][2]["_type"]).to eq page2.column_values[2].class.name
            expect(cms_page["column_values"][2]["column_id"]).to eq("$oid" => page2.column_values[2].column.id.to_s)
            expect(cms_page["column_values"][2]["name"]).to eq page2.column_values[2].name
            expect(cms_page["column_values"][2]["order"]).to eq page2.column_values[2].order
            expect(cms_page["column_values"][2]["value"]).to eq page2.column_values[2].value
            expect(cms_page["column_values"][2]["file_ids"]).to eq page2.column_values[2].file_ids
          end

          cms_pages[2].tap do |cms_page|
            expect(cms_page["name"]).to eq page3.name
            expect(cms_page["filename"]).to eq page3.filename
            expect(cms_page["column_values"]).to be_a(Array)
            expect(cms_page["column_values"][0]["_type"]).to eq page3.column_values[0].class.name
            expect(cms_page["column_values"][0]["column_id"]).to eq("$oid" => page3.column_values[0].column.id.to_s)
            expect(cms_page["column_values"][0]["name"]).to eq page3.column_values[0].name
            expect(cms_page["column_values"][0]["order"]).to eq page3.column_values[0].order
            expect(cms_page["column_values"][0]["value"]).to eq page3.column_values[0].value
            expect(cms_page["column_values"][1]["_type"]).to eq page3.column_values[1].class.name
            expect(cms_page["column_values"][1]["column_id"]).to eq("$oid" => page3.column_values[1].column.id.to_s)
            expect(cms_page["column_values"][1]["name"]).to eq page3.column_values[1].name
            expect(cms_page["column_values"][1]["order"]).to eq page3.column_values[1].order
            expect(cms_page["column_values"][1]["value"]).to eq page3.column_values[1].value
            expect(cms_page["column_values"][2]["_type"]).to eq page3.column_values[2].class.name
            expect(cms_page["column_values"][2]["column_id"]).to eq("$oid" => page3.column_values[2].column.id.to_s)
            expect(cms_page["column_values"][2]["name"]).to eq page3.column_values[2].name
            expect(cms_page["column_values"][2]["order"]).to eq page3.column_values[2].order
            expect(cms_page["column_values"][2]["file_id"]).to eq page3.column_values[2].file_id
            expect(cms_page["column_values"][3]["_type"]).to eq page3.column_values[3].class.name
            expect(cms_page["column_values"][3]["column_id"]).to eq("$oid" => page3.column_values[3].column.id.to_s)
            expect(cms_page["column_values"][3]["name"]).to eq page3.column_values[3].name
            expect(cms_page["column_values"][3]["order"]).to eq page3.column_values[3].order
            expect(cms_page["column_values"][3]["file_id"]).to eq page3.column_values[3].file_id
            expect(cms_page["column_values"][4]["_type"]).to eq page3.column_values[4].class.name
            expect(cms_page["column_values"][4]["column_id"]).to eq("$oid" => page3.column_values[4].column.id.to_s)
            expect(cms_page["column_values"][4]["name"]).to eq page3.column_values[4].name
            expect(cms_page["column_values"][4]["order"]).to eq page3.column_values[4].order
            expect(cms_page["column_values"][4]["value"]).to eq page3.column_values[4].value
            expect(cms_page["column_values"][4]["file_ids"]).to eq page3.column_values[4].file_ids
            expect(cms_page["column_values"][5]["_type"]).to eq page3.column_values[5].class.name
            expect(cms_page["column_values"][5]["column_id"]).to eq("$oid" => page3.column_values[5].column.id.to_s)
            expect(cms_page["column_values"][5]["name"]).to eq page3.column_values[5].name
            expect(cms_page["column_values"][5]["order"]).to eq page3.column_values[5].order
            expect(cms_page["column_values"][5]["value"]).to eq page3.column_values[5].value
            expect(cms_page["column_values"][5]["file_ids"]).to eq page3.column_values[5].file_ids
          end
        end
        JSON.parse(zip.read(zip.get_entry("ss_files.json"))).tap do |ss_files|
          expect(ss_files).to be_a(Array)
          expect(ss_files.length).to eq 14

          expect(ss_files[0]["_id"]).to eq page1_file1.id
          expect(ss_files[0]["model"]).to eq page1_file1.model
          expect(ss_files[0]["name"]).to eq page1_file1.name
          expect(ss_files[0]["filename"]).to eq page1_file1.filename
          expect(ss_files[0]["state"]).to eq page1_file1.state
          expect(zip.get_entry(ss_files[0]["export_path"])).to be_present

          expect(ss_files[2]["_id"]).to eq page2_file1.id
          expect(ss_files[2]["model"]).to eq page2_file1.model
          expect(ss_files[2]["name"]).to eq page2_file1.name
          expect(ss_files[2]["filename"]).to eq page2_file1.filename
          expect(ss_files[2]["state"]).to eq page2_file1.state
          expect(zip.get_entry(ss_files[2]["export_path"])).to be_present

          expect(ss_files[4]["_id"]).to eq page2_file2.id
          expect(ss_files[4]["model"]).to eq page2_file2.model
          expect(ss_files[4]["name"]).to eq page2_file2.name
          expect(ss_files[4]["filename"]).to eq page2_file2.filename
          expect(ss_files[4]["state"]).to eq page2_file2.state
          expect(zip.get_entry(ss_files[4]["export_path"])).to be_present

          expect(ss_files[6]["_id"]).to eq page3_file1.id
          expect(ss_files[6]["model"]).to eq page3_file1.model
          expect(ss_files[6]["name"]).to eq page3_file1.name
          expect(ss_files[6]["filename"]).to eq page3_file1.filename
          expect(ss_files[6]["state"]).to eq page3_file1.state
          expect(zip.get_entry(ss_files[6]["export_path"])).to be_present

          expect(ss_files[8]["_id"]).to eq page3_file2.id
          expect(ss_files[8]["model"]).to eq page3_file2.model
          expect(ss_files[8]["name"]).to eq page3_file2.name
          expect(ss_files[8]["filename"]).to eq page3_file2.filename
          expect(ss_files[8]["state"]).to eq page3_file2.state
          expect(zip.get_entry(ss_files[8]["export_path"])).to be_present

          expect(ss_files[10]["_id"]).to eq page3_file3.id
          expect(ss_files[10]["model"]).to eq page3_file3.model
          expect(ss_files[10]["name"]).to eq page3_file3.name
          expect(ss_files[10]["filename"]).to eq page3_file3.filename
          expect(ss_files[10]["state"]).to eq page3_file3.state
          expect(zip.get_entry(ss_files[10]["export_path"])).to be_present

          expect(ss_files[12]["_id"]).to eq page3_file4.id
          expect(ss_files[12]["model"]).to eq page3_file4.model
          expect(ss_files[12]["name"]).to eq page3_file4.name
          expect(ss_files[12]["filename"]).to eq page3_file4.filename
          expect(ss_files[12]["state"]).to eq page3_file4.state
          expect(zip.get_entry(ss_files[12]["export_path"])).to be_present
        end
      end
    end
  end

  context 'with inquiry' do
    let!(:node) { create :inquiry_node_form, cur_site: site }
    let!(:column_name) { node.columns.create! attributes_for(:inquiry_column_name).reverse_merge({cur_site: site}) }
    let!(:column_optional) { node.columns.create! attributes_for(:inquiry_column_optional).reverse_merge({cur_site: site}) }
    let!(:column_transfers) { node.columns.create! attributes_for(:inquiry_column_transfers).reverse_merge({cur_site: site}) }
    let!(:column_email) { node.columns.create! attributes_for(:inquiry_column_email).reverse_merge({cur_site: site}) }
    let!(:column_radio) { node.columns.create! attributes_for(:inquiry_column_radio).reverse_merge({cur_site: site}) }
    let!(:column_select) { node.columns.create! attributes_for(:inquiry_column_select).reverse_merge({cur_site: site}) }
    let!(:column_check) { node.columns.create! attributes_for(:inquiry_column_check).reverse_merge({cur_site: site}) }
    let!(:column_upload_file) { node.columns.create! attributes_for(:inquiry_column_upload_file).reverse_merge({cur_site: site}) }

    before do
      node.reload
    end

    it do
      zip_path = execute
      # ::FileUtils.cp(zip_path, "#{Rails.root}/spec/fixtures/sys/site-exports-2.zip")
      Zip::File.open(zip_path) do |zip|
        JSON.parse(zip.read(zip.get_entry("cms_nodes.json"))).tap do |cms_nodes|
          expect(cms_nodes).to be_a(Array)
          expect(cms_nodes.length).to eq 1

          cms_nodes[0].tap do |cms_node|
            expect(cms_node["name"]).to eq node.name
            expect(cms_node["filename"]).to eq node.filename
          end
        end

        JSON.parse(zip.read(zip.get_entry("inquiry_columns.json"))).tap do |inquiry_columns|
          expect(inquiry_columns).to be_a(Array)
          expect(inquiry_columns.length).to eq 8

          inquiry_columns[0].tap do |inquiry_column|
            expect(inquiry_column["node_id"]).to eq column_name.node.id
            expect(inquiry_column["name"]).to eq column_name.name
            expect(inquiry_column["input_type"]).to eq column_name.input_type
            expect(inquiry_column["required"]).to eq column_name.required
            expect(inquiry_column["html"]).to eq column_name.html
            expect(inquiry_column["order"]).to eq column_name.order
          end

          inquiry_columns[1].tap do |inquiry_column|
            expect(inquiry_column["node_id"]).to eq column_optional.node.id
            expect(inquiry_column["name"]).to eq column_optional.name
            expect(inquiry_column["input_type"]).to eq column_optional.input_type
            expect(inquiry_column["required"]).to eq column_optional.required
            expect(inquiry_column["html"]).to eq column_optional.html
            expect(inquiry_column["order"]).to eq column_optional.order
          end

          inquiry_columns[2].tap do |inquiry_column|
            expect(inquiry_column["node_id"]).to eq column_transfers.node.id
            expect(inquiry_column["name"]).to eq column_transfers.name
            expect(inquiry_column["input_type"]).to eq column_transfers.input_type
            expect(inquiry_column["required"]).to eq column_transfers.required
            expect(inquiry_column["html"]).to eq column_transfers.html
            expect(inquiry_column["transfers"][0]["keyword"]).to eq column_transfers.transfers[0][:keyword]
            expect(inquiry_column["transfers"][0]["email"]).to eq column_transfers.transfers[0][:email]
            expect(inquiry_column["order"]).to eq column_transfers.order
          end

          inquiry_columns[3].tap do |inquiry_column|
            expect(inquiry_column["node_id"]).to eq column_email.node.id
            expect(inquiry_column["name"]).to eq column_email.name
            expect(inquiry_column["input_type"]).to eq column_email.input_type
            expect(inquiry_column["required"]).to eq column_email.required
            expect(inquiry_column["input_confirm"]).to eq column_email.input_confirm
            expect(inquiry_column["html"]).to eq column_email.html
            expect(inquiry_column["order"]).to eq column_email.order
          end

          inquiry_columns[4].tap do |inquiry_column|
            expect(inquiry_column["node_id"]).to eq column_radio.node.id
            expect(inquiry_column["name"]).to eq column_radio.name
            expect(inquiry_column["input_type"]).to eq column_radio.input_type
            expect(inquiry_column["required"]).to eq column_radio.required
            expect(inquiry_column["html"]).to eq column_radio.html
            expect(inquiry_column["select_options"]).to eq column_radio.select_options
            expect(inquiry_column["order"]).to eq column_radio.order
          end

          inquiry_columns[5].tap do |inquiry_column|
            expect(inquiry_column["node_id"]).to eq column_select.node.id
            expect(inquiry_column["name"]).to eq column_select.name
            expect(inquiry_column["input_type"]).to eq column_select.input_type
            expect(inquiry_column["required"]).to eq column_select.required
            expect(inquiry_column["html"]).to eq column_select.html
            expect(inquiry_column["select_options"]).to eq column_select.select_options
            expect(inquiry_column["order"]).to eq column_select.order
          end

          inquiry_columns[6].tap do |inquiry_column|
            expect(inquiry_column["node_id"]).to eq column_check.node.id
            expect(inquiry_column["name"]).to eq column_check.name
            expect(inquiry_column["input_type"]).to eq column_check.input_type
            expect(inquiry_column["required"]).to eq column_check.required
            expect(inquiry_column["html"]).to eq column_check.html
            expect(inquiry_column["select_options"]).to eq column_check.select_options
            expect(inquiry_column["order"]).to eq column_check.order
          end

          inquiry_columns[7].tap do |inquiry_column|
            expect(inquiry_column["node_id"]).to eq column_upload_file.node.id
            expect(inquiry_column["name"]).to eq column_upload_file.name
            expect(inquiry_column["input_type"]).to eq column_upload_file.input_type
            expect(inquiry_column["required"]).to eq column_upload_file.required
            expect(inquiry_column["html"]).to eq column_upload_file.html
            expect(inquiry_column["max_upload_file_size"]).to eq column_upload_file.max_upload_file_size
            expect(inquiry_column["order"]).to eq column_upload_file.order
          end
        end
      end
    end
  end
end
