require 'spec_helper'

describe 'file_repairer:duplicates', dbscope: :example do
  let!(:site1) { cms_site }
  let!(:site2) { create :cms_site, name: "site2", host: "site2", domains: "site2.example.jp" }

  # default form
  let!(:node1) { create(:article_node_page, filename: "docs1") }
  let!(:item1) { create(:article_page, name: "item1", cur_node: node1) }
  let!(:item2) { create(:article_page, name: "item2", cur_node: node1) }

  # cms form
  let!(:node2) { create(:article_node_page, filename: "docs2", st_form_ids: [form.id]) }
  let!(:form) { create(:cms_form, cur_site: site1, state: 'public', sub_type: 'entry', html: nil) }
  let!(:column) { create(:cms_column_free, cur_form: form, required: "optional") }

  let!(:item3) { create(:article_page, name: "item3", cur_node: node2, form: form, column_values: [column_value1]) }
  let(:column_value1) { column.value_type.new(column: column) }

  # another site
  let!(:node_site2) { create(:article_node_page, filename: "docs", cur_site: site2) }
  let!(:item_site2) { create(:article_page, cur_node: node_site2, cur_site: site2) }

  # files
  let(:ss_file1) { create :ss_file, site: site1, owner_item: item1, state: "public", in_file: image_file }
  let(:ss_file2) { create :ss_file, site: site1, owner_item: item1, state: "public", in_file: image_file }
  let(:ss_file3) { create :ss_file, site: site1, owner_item: item2, state: "public", in_file: image_file }
  let(:ss_file4) { create :ss_file, site: site1, owner_item: item2, state: "public", in_file: image_file }
  let(:ss_file5) { create :ss_file, site: site1, owner_item: item3, state: "public", in_file: image_file }
  let(:ss_file6) { create :ss_file, site: site1, owner_item: item3, state: "public", in_file: pdf_file }

  let(:csv_header) { %w(ID タイトル ステータス 公開画面 管理画面 ファイルID ファイルURL エラー) }

  def image_file
    Fs::UploadedFile.create_from_file "#{Rails.root}/spec/fixtures/ss/logo.png", content_type: 'image/png'
  end

  def pdf_file
    Fs::UploadedFile.create_from_file "#{Rails.root}/db/seeds/gws/files/file.pdf", content_type: 'application/pdf'
  end

  def html_include_files(*files)
    files.map do |file|
      "<a href=\"#{file.url}\">#{file.name}</a>"
    end.join("\n")
  end

  def save_files
    item1.html = html_include_files(ss_file1, ss_file2)
    item1.file_ids = [ss_file1.id, ss_file2.id]
    item1.update!
    item1.reload

    item2.html = html_include_files(ss_file3, ss_file4)
    item2.file_ids = [ss_file3.id, ss_file4.id]
    item2.update!
    item2.reload

    value = item3.column_values[0]
    value.value = html_include_files(ss_file5, ss_file6)
    value.file_ids = [ss_file5.id, ss_file6.id]
    item3.update!
    item3.reload
  end

  context "no errors" do
    before { save_files }

    it do
      # check
      repairer = Cms::FileRepair::Repairer.new
      repairer.check_duplicates(site1)
      table = CSV.read(repairer.csv_path, headers: true, encoding: 'BOM|UTF-8')
      expect(table.headers).to eq csv_header
      expect(table.size).to eq 0

      # delete
      repairer = Cms::FileRepair::Repairer.new
      repairer.delete_duplicates(site1)
      table = CSV.read(repairer.csv_path, headers: true, encoding: 'BOM|UTF-8')
      expect(table.headers).to eq csv_header
      expect(table.size).to eq 0

      # check
      repairer = Cms::FileRepair::Repairer.new
      repairer.check_duplicates(site1)
      table = CSV.read(repairer.csv_path, headers: true, encoding: 'BOM|UTF-8')
      expect(table.headers).to eq csv_header
      expect(table.size).to eq 0
    end
  end

  context "deletable files exists" do
    before do
      save_files

      item1.html = html_include_files(ss_file1)
      item1.file_ids = [ss_file1.id, ss_file2.id]
      item1.update!
      item1.reload

      item2.html = html_include_files(ss_file3, ss_file4)
      item2.file_ids = [ss_file3.id, ss_file4.id]
      item2.update!
      item2.reload

      value = item3.column_values[0]
      value.value = html_include_files(ss_file5)
      value.file_ids = [ss_file5.id, ss_file6.id]
      item3.update!
      item3.reload
    end

    it do
      # check
      repairer = Cms::FileRepair::Repairer.new
      repairer.check_duplicates(site1)
      table = CSV.read(repairer.csv_path, headers: true, encoding: 'BOM|UTF-8')
      expect(table.headers).to eq csv_header
      expect(table.size).to eq 1

      expect(SS::File.in(id: ss_file1.id).size).to eq 1
      expect(SS::File.in(id: ss_file2.id).size).to eq 1
      expect(SS::File.in(id: ss_file3.id).size).to eq 1
      expect(SS::File.in(id: ss_file4.id).size).to eq 1
      expect(SS::File.in(id: ss_file5.id).size).to eq 1
      expect(SS::File.in(id: ss_file6.id).size).to eq 1

      # delete
      repairer = Cms::FileRepair::Repairer.new
      repairer.delete_duplicates(site1)
      table = CSV.read(repairer.csv_path, headers: true, encoding: 'BOM|UTF-8')
      expect(table.headers).to eq csv_header
      expect(table.size).to eq 1

      expect(SS::File.in(id: ss_file1.id).size).to eq 1
      expect(SS::File.in(id: ss_file2.id).size).to eq 0
      expect(SS::File.in(id: ss_file3.id).size).to eq 1
      expect(SS::File.in(id: ss_file4.id).size).to eq 1
      expect(SS::File.in(id: ss_file5.id).size).to eq 1
      expect(SS::File.in(id: ss_file6.id).size).to eq 1

      # check
      repairer = Cms::FileRepair::Repairer.new
      repairer.check_duplicates(site1)
      table = CSV.read(repairer.csv_path, headers: true, encoding: 'BOM|UTF-8')
      expect(table.headers).to eq csv_header
      expect(table.size).to eq 0

      expect(SS::File.in(id: ss_file1.id).size).to eq 1
      expect(SS::File.in(id: ss_file2.id).size).to eq 0
      expect(SS::File.in(id: ss_file3.id).size).to eq 1
      expect(SS::File.in(id: ss_file4.id).size).to eq 1
      expect(SS::File.in(id: ss_file5.id).size).to eq 1
      expect(SS::File.in(id: ss_file6.id).size).to eq 1
    end
  end
end
