require 'spec_helper'

describe Cms::Elasticsearch::PageConvertor, type: :model, dbscope: :example, es: true do
  let(:group) { cms_group }
  let(:site) { cms_site }
  let(:user) { cms_user }
  let(:name) { unique_id }
  let(:filename) { "#{unique_id}.html" }

  context "with cms_page and file" do
    let(:category) { create :category_node_page }
    let!(:file) { create :ss_file, user_id: user.id }
    let(:cms_page) do
      create(
        :cms_page, cur_site: site, name: name, filename: filename, file_ids: [file.id],
        category_ids: [category.id], state: 'public', group_ids: [group.id]
      )
    end
    let(:item) { described_class.with_route(cms_page, index_item_id: cms_page.filename) }

    it do
      expect(item.enum_es_docs.to_a.size).to eq 2

      expect(item.enum_es_docs.to_a[0][0]).to eq filename
      expect(item.enum_es_docs.to_a[0][1][:url]).to eq cms_page.url
      expect(item.enum_es_docs.to_a[0][1][:name]).to eq name
      expect(item.enum_es_docs.to_a[0][1][:text]).to eq item.item_text
      expect(item.enum_es_docs.to_a[0][1][:filename]).to eq cms_page.path
      expect(item.enum_es_docs.to_a[0][1][:state]).to eq 'public'
      expect(item.enum_es_docs.to_a[0][1][:categories]).to eq [category.name]
      expect(item.enum_es_docs.to_a[0][1][:category_ids]).to eq [category.id]
      expect(item.enum_es_docs.to_a[0][1][:group_ids]).to eq [group.id]
      # expect(item.enum_es_docs.to_a[0][1][:released]).to eq cms_page.released.try(:iso8601)
      # expect(item.enum_es_docs.to_a[0][1][:updated]).to eq cms_page.updated.try(:iso8601)
      # expect(item.enum_es_docs.to_a[0][1][:created]).to eq cms_page.created.try(:iso8601)

      expect(item.enum_es_docs.to_a[1][0]).to eq "file-#{file.id}"
      expect(item.enum_es_docs.to_a[1][1][:url]).to eq cms_page.url
      expect(item.enum_es_docs.to_a[1][1][:name]).to eq file.name
      expect(item.enum_es_docs.to_a[1][1][:data]).to eq Base64.strict_encode64(::File.binread(file.path))
      expect(item.enum_es_docs.to_a[1][1][:file][:extname]).to eq 'PNG'
      expect(item.enum_es_docs.to_a[1][1][:file][:size]).to eq file.size
      expect(item.enum_es_docs.to_a[1][1][:path]).to eq cms_page.path
      expect(item.enum_es_docs.to_a[1][1][:state]).to eq 'public'
      # expect(item.enum_es_docs.to_a[1][1][:released]).to eq cms_page.released.try(:iso8601)
      # expect(item.enum_es_docs.to_a[1][1][:updated]).to eq file.updated.try(:iso8601)
      # expect(item.enum_es_docs.to_a[1][1][:created]).to eq file.created.try(:iso8601)
    end
  end

  context "with cms_page, form and file" do
    let(:category) { create :category_node_page }
    let!(:file) { create :ss_file, user_id: user.id }
    let(:form) { create :cms_form, cur_site: site, state: 'public', sub_type: 'entry' }
    let(:column1) do
      create(:cms_column_text_field, cur_site: site, cur_form: form, required: "optional", order: 1, input_type: 'text')
    end
    let(:column2) do
      create(:cms_column_date_field, cur_site: site, cur_form: form, required: "optional", order: 2)
    end
    let(:column3) do
      create(:cms_column_url_field2, cur_site: site, cur_form: form, required: "optional", order: 3, html_tag: '')
    end
    let(:column4) do
      create(:cms_column_text_area, cur_site: site, cur_form: form, required: "optional", order: 4)
    end
    let(:column5) do
      create(:cms_column_select, cur_site: site, cur_form: form, required: "optional", order: 5)
    end
    let(:column6) do
      create(:cms_column_radio_button, cur_site: site, cur_form: form, required: "optional", order: 6)
    end
    let(:column7) do
      create(:cms_column_check_box, cur_site: site, cur_form: form, required: "optional", order: 7)
    end
    let(:column8) do
      create(:cms_column_file_upload, cur_site: site, cur_form: form, required: "optional", order: 8, file_type: "image")
    end
    let(:column9) do
      create(:cms_column_free, cur_site: site, cur_form: form, required: "optional", order: 9)
    end
    let(:column10) do
      create(:cms_column_headline, cur_site: site, cur_form: form, required: "optional", order: 10)
    end
    let(:column11) do
      create(:cms_column_list, cur_site: site, cur_form: form, required: "optional", order: 11)
    end
    let(:column12) do
      create(:cms_column_table, cur_site: site, cur_form: form, required: "optional", order: 12)
    end
    let(:column13) do
      create(:cms_column_youtube, cur_site: site, cur_form: form, required: "optional", order: 13)
    end
    let(:column_values) do
      [
        column1.value_type.new(column: column1, value: unique_id),
        column2.value_type.new(column: column2, date: Time.zone.now),
        column3.value_type.new(column: column3, link_url: unique_id),
        column4.value_type.new(column: column4, value: unique_id),
        column5.value_type.new(column: column5, value: column5.select_options.sample),
        column6.value_type.new(column: column6, value: column6.select_options.sample),
        column7.value_type.new(column: column7, values: [column7.select_options.sample]),
        column8.value_type.new(column: column8, file: file),
        column9.value_type.new(column: column9, value: unique_id, file_ids: [file.id]),
        column10.value_type.new(column: column10, text: unique_id),
        column11.value_type.new(column: column11, lists: [unique_id]),
        column12.value_type.new(column: column12, value: unique_id),
        column13.value_type.new(column: column13, url: "https://www.youtube.com/watch?v=CSlLndeDc48"),
      ]
    end
    let(:cms_page) do
      create(
        :cms_page, cur_site: site, name: name, filename: filename, form: form,
        category_ids: [category.id], state: 'public', group_ids: [group.id]
      )
    end
    let(:item) { described_class.with_route(cms_page, index_item_id: cms_page.filename) }

    before do
      cms_page.column_values = column_values
      cms_page.save!
      cms_page.reload
    end

    it do
      expect(item.enum_es_docs.to_a.size).to eq 3

      expect(item.enum_es_docs.to_a[0][0]).to eq filename
      expect(item.enum_es_docs.to_a[0][1][:url]).to eq cms_page.url
      expect(item.enum_es_docs.to_a[0][1][:name]).to eq name
      expect(item.enum_es_docs.to_a[0][1][:text]).to eq item.item_text
      expect(item.enum_es_docs.to_a[0][1][:filename]).to eq cms_page.path
      expect(item.enum_es_docs.to_a[0][1][:state]).to eq 'public'
      expect(item.enum_es_docs.to_a[0][1][:categories]).to eq [category.name]
      expect(item.enum_es_docs.to_a[0][1][:category_ids]).to eq [category.id]
      expect(item.enum_es_docs.to_a[0][1][:group_ids]).to eq [group.id]
      # expect(item.enum_es_docs.to_a[0][1][:released]).to eq cms_page.released.try(:iso8601)
      # expect(item.enum_es_docs.to_a[0][1][:updated]).to eq cms_page.updated.try(:iso8601)
      # expect(item.enum_es_docs.to_a[0][1][:created]).to eq cms_page.created.try(:iso8601)

      expect(item.enum_es_docs.to_a[1][0]).to eq "file-#{file.id}"
      expect(item.enum_es_docs.to_a[1][1][:url]).to eq cms_page.url
      expect(item.enum_es_docs.to_a[1][1][:name]).to eq file.name
      expect(item.enum_es_docs.to_a[1][1][:data]).to eq Base64.strict_encode64(::File.binread(file.path))
      expect(item.enum_es_docs.to_a[1][1][:file][:extname]).to eq 'PNG'
      expect(item.enum_es_docs.to_a[1][1][:file][:size]).to eq file.size
      expect(item.enum_es_docs.to_a[1][1][:path]).to eq cms_page.path
      expect(item.enum_es_docs.to_a[1][1][:state]).to eq 'public'
      # expect(item.enum_es_docs.to_a[1][1][:released]).to eq cms_page.released.try(:iso8601)
      # expect(item.enum_es_docs.to_a[1][1][:updated]).to eq file.updated.try(:iso8601)
      # expect(item.enum_es_docs.to_a[1][1][:created]).to eq file.created.try(:iso8601)

      expect(item.enum_es_docs.to_a[2][0]).to eq "file-#{file.id}"
      expect(item.enum_es_docs.to_a[2][1][:url]).to eq cms_page.url
      expect(item.enum_es_docs.to_a[2][1][:name]).to eq file.name
      expect(item.enum_es_docs.to_a[2][1][:data]).to eq Base64.strict_encode64(::File.binread(file.path))
      expect(item.enum_es_docs.to_a[2][1][:file][:extname]).to eq 'PNG'
      expect(item.enum_es_docs.to_a[2][1][:file][:size]).to eq file.size
      expect(item.enum_es_docs.to_a[2][1][:path]).to eq cms_page.path
      expect(item.enum_es_docs.to_a[2][1][:state]).to eq 'public'
      # expect(item.enum_es_docs.to_a[2][1][:released]).to eq cms_page.released.try(:iso8601)
      # expect(item.enum_es_docs.to_a[2][1][:updated]).to eq file.updated.try(:iso8601)
      # expect(item.enum_es_docs.to_a[2][1][:created]).to eq file.created.try(:iso8601)
    end
  end

  context "with opendata_app and appfile" do
    let(:node) { create :opendata_node_app, cur_site: cms_site }
    let!(:node_app_search) { create :opendata_node_search_app, cur_site: site }
    let(:category) { create :opendata_node_category, cur_site: site }
    let(:file_path) { Rails.root.join("spec", "fixtures", "opendata", "utf-8.csv") }
    let(:file) { Fs::UploadedFile.create_from_file(file_path, basename: "spec") }
    let(:app) do
      create(
        :opendata_app, cur_site: site, cur_node: node, name: name, basename: filename,
        category_ids: [category.id], state: 'public', group_ids: [group.id]
      )
    end
    let(:item) { described_class.with_route(app, index_item_id: app.filename) }

    before do
      appfile = app.appfiles.new(text: 'utf-8', format: 'csv')
      appfile.in_file = file
      appfile.save
    end

    it do
      expect(item.enum_es_docs.to_a.size).to eq 2

      expect(item.enum_es_docs.to_a[0][0]).to eq "#{node.filename}/#{filename}"
      expect(item.enum_es_docs.to_a[0][1][:url]).to eq app.url
      expect(item.enum_es_docs.to_a[0][1][:name]).to eq name
      expect(item.enum_es_docs.to_a[0][1][:text]).to eq item.item_text
      expect(item.enum_es_docs.to_a[0][1][:filename]).to eq app.path
      expect(item.enum_es_docs.to_a[0][1][:state]).to eq 'public'
      expect(item.enum_es_docs.to_a[0][1][:categories]).to eq [category.name]
      expect(item.enum_es_docs.to_a[0][1][:category_ids]).to eq [category.id]
      expect(item.enum_es_docs.to_a[0][1][:group_ids]).to eq [group.id]
      # expect(item.enum_es_docs.to_a[0][1][:released]).to eq app.released.try(:iso8601)
      # expect(item.enum_es_docs.to_a[0][1][:updated]).to eq app.updated.try(:iso8601)
      # expect(item.enum_es_docs.to_a[0][1][:created]).to eq app.created.try(:iso8601)

      expect(item.enum_es_docs.to_a[1][0]).to eq "file-#{app.appfiles.first.file_id}"
      expect(item.enum_es_docs.to_a[1][1][:url]).to eq app.url
      expect(item.enum_es_docs.to_a[1][1][:name]).to eq 'utf-8.csv'
      expect(item.enum_es_docs.to_a[1][1][:data]).to eq Base64.strict_encode64(::File.binread(file.path))
      expect(item.enum_es_docs.to_a[1][1][:file][:extname]).to eq 'CSV'
      expect(item.enum_es_docs.to_a[1][1][:file][:size]).to eq app.appfiles.first.size
      expect(item.enum_es_docs.to_a[1][1][:path]).to eq app.path
      expect(item.enum_es_docs.to_a[1][1][:state]).to eq 'public'
      # expect(item.enum_es_docs.to_a[1][1][:released]).to eq app.released.try(:iso8601)
      # expect(item.enum_es_docs.to_a[1][1][:updated]).to eq app.appfiles.first.updated.try(:iso8601)
      # expect(item.enum_es_docs.to_a[1][1][:created]).to eq app.appfiles.first.created.try(:iso8601)
    end
  end

  context "with opendata_dataset and resource" do
    let(:node) { create :opendata_node_dataset, cur_site: cms_site }
    let!(:node_dataset_search) { create :opendata_node_search_dataset, cur_site: site }
    let(:category) { create :opendata_node_category, cur_site: site }
    let(:license) { create(:opendata_license, cur_site: site) }
    let(:file_path) { Rails.root.join("spec", "fixtures", "opendata", "utf-8.csv") }
    let(:file) { Fs::UploadedFile.create_from_file(file_path, basename: "spec") }
    let(:dataset) do
      create(
        :opendata_dataset, cur_site: site, cur_node: node, name: name, basename: filename,
        category_ids: [category.id], state: 'public', group_ids: [group.id]
      )
    end
    let(:item) { described_class.with_route(dataset, index_item_id: dataset.filename) }

    before do
      resource = dataset.resources.new(name: 'utf-8.csv', format: 'csv', license: license)
      resource.in_file = file
      resource.save
    end

    it do
      expect(item.enum_es_docs.to_a.size).to eq 2

      expect(item.enum_es_docs.to_a[0][0]).to eq "#{node.filename}/#{filename}"
      expect(item.enum_es_docs.to_a[0][1][:url]).to eq dataset.url
      expect(item.enum_es_docs.to_a[0][1][:name]).to eq name
      expect(item.enum_es_docs.to_a[0][1][:text]).to eq item.item_text
      expect(item.enum_es_docs.to_a[0][1][:filename]).to eq dataset.path
      expect(item.enum_es_docs.to_a[0][1][:state]).to eq 'public'
      expect(item.enum_es_docs.to_a[0][1][:categories]).to eq [category.name]
      expect(item.enum_es_docs.to_a[0][1][:category_ids]).to eq [category.id]
      expect(item.enum_es_docs.to_a[0][1][:group_ids]).to eq [group.id]
      # expect(item.enum_es_docs.to_a[0][1][:released]).to eq app.released.try(:iso8601)
      # expect(item.enum_es_docs.to_a[0][1][:updated]).to eq app.updated.try(:iso8601)
      # expect(item.enum_es_docs.to_a[0][1][:created]).to eq app.created.try(:iso8601)

      expect(item.enum_es_docs.to_a[1][0]).to eq "file-#{dataset.resources.first.file_id}"
      expect(item.enum_es_docs.to_a[1][1][:url]).to eq dataset.url
      expect(item.enum_es_docs.to_a[1][1][:name]).to eq 'utf-8.csv'
      expect(item.enum_es_docs.to_a[1][1][:data]).to eq Base64.strict_encode64(::File.binread(file.path))
      expect(item.enum_es_docs.to_a[1][1][:file][:extname]).to eq 'CSV'
      expect(item.enum_es_docs.to_a[1][1][:file][:size]).to eq dataset.resources.first.size
      expect(item.enum_es_docs.to_a[1][1][:path]).to eq dataset.path
      expect(item.enum_es_docs.to_a[1][1][:state]).to eq 'public'
      # expect(item.enum_es_docs.to_a[1][1][:released]).to eq app.released.try(:iso8601)
      # expect(item.enum_es_docs.to_a[1][1][:updated]).to eq app.appfiles.first.updated.try(:iso8601)
      # expect(item.enum_es_docs.to_a[1][1][:created]).to eq app.appfiles.first.created.try(:iso8601)
    end
  end
end
