require 'spec_helper'

describe 'file_repairer:check_states', dbscope: :example do
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
  let(:ss_file1) { create :ss_file, site: site1, owner_item: item1, state: "public" }
  let(:ss_file2) { create :ss_file, site: site1, owner_item: item1, state: "public" }
  let(:ss_file3) { create :ss_file, site: site1, owner_item: item2, state: "public" }
  let(:ss_file4) { create :ss_file, site: site1, owner_item: item2, state: "public" }
  let(:ss_file5) { create :ss_file, site: site1, owner_item: item3, state: "public" }
  let(:ss_file6) { create :ss_file, site: site1, owner_item: item3, state: "public" }

  let(:csv_header) { %w(ID タイトル ステータス 公開画面 管理画面 ファイルID ファイルURL エラー) }

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
      repairer.check_states(site1)
      table = CSV.read(repairer.csv_path, headers: true, encoding: 'BOM|UTF-8')
      expect(table.headers).to eq csv_header
      expect(table.size).to eq 0

      # fix
      repairer = Cms::FileRepair::Repairer.new
      repairer.fix_states(site1)
      table = CSV.read(repairer.csv_path, headers: true, encoding: 'BOM|UTF-8')
      expect(table.headers).to eq csv_header
      expect(table.size).to eq 0

      # check
      repairer = Cms::FileRepair::Repairer.new
      repairer.check_states(site1)
      table = CSV.read(repairer.csv_path, headers: true, encoding: 'BOM|UTF-8')
      expect(table.headers).to eq csv_header
      expect(table.size).to eq 0
    end
  end

  context "page and file state unmatched" do
    before do
      save_files

      item1.set(state: "public")
      item1.files.each { |file| file.set(state: "closed") }

      item2.set(state: "closed")
      item2.files.each { |file| file.set(state: "public") }

      item3.column_values[0].files.each { |file| file.unset(:site_id) }
    end

    it do
      # check
      repairer = Cms::FileRepair::Repairer.new
      repairer.check_states(site1)
      table = CSV.read(repairer.csv_path, headers: true, encoding: 'BOM|UTF-8')
      expect(table.headers).to eq csv_header
      expect(table.size).to eq 6

      files = {}
      table.each do |row|
        files[row["ファイルID"].to_i] = row["エラー"]
      end
      expect(files[ss_file1.id]).to eq "ページが公開状態だが、ファイルは非公開状態"
      expect(files[ss_file2.id]).to eq "ページが公開状態だが、ファイルは非公開状態"
      expect(files[ss_file3.id]).to eq "ページが非公開状態だが、ファイルは公開状態"
      expect(files[ss_file4.id]).to eq "ページが非公開状態だが、ファイルは公開状態"
      expect(files[ss_file5.id]).to eq "site が設定されていない"
      expect(files[ss_file6.id]).to eq "site が設定されていない"

      ss_file1.reload
      ss_file2.reload
      ss_file3.reload
      ss_file4.reload
      ss_file5.reload
      ss_file6.reload
      expect(ss_file1.state).to eq "closed"
      expect(ss_file2.state).to eq "closed"
      expect(ss_file3.state).to eq "public"
      expect(ss_file4.state).to eq "public"
      expect(ss_file5.site_id).to eq nil
      expect(ss_file6.site_id).to eq nil

      # fix
      repairer = Cms::FileRepair::Repairer.new
      repairer.fix_states(site1)
      table = CSV.read(repairer.csv_path, headers: true, encoding: 'BOM|UTF-8')
      expect(table.headers).to eq csv_header
      expect(table.size).to eq 6

      ss_file1.reload
      ss_file2.reload
      ss_file3.reload
      ss_file4.reload
      ss_file5.reload
      ss_file6.reload
      expect(ss_file1.state).to eq "public"
      expect(ss_file2.state).to eq "public"
      expect(ss_file3.state).to eq "closed"
      expect(ss_file4.state).to eq "closed"
      expect(ss_file5.site_id).to eq site1.id
      expect(ss_file6.site_id).to eq site1.id

      # check
      repairer = Cms::FileRepair::Repairer.new
      repairer.check_states(site1)
      table = CSV.read(repairer.csv_path, headers: true, encoding: 'BOM|UTF-8')
      expect(table.headers).to eq csv_header
      expect(table.size).to eq 0
    end
  end

  context "file_id unincluded in file_ids" do
    before do
      save_files

      value = item3.column_values[0]
      value.set(file_ids: [])
    end

    it do
      # check
      repairer = Cms::FileRepair::Repairer.new
      repairer.check_states(site1)
      table = CSV.read(repairer.csv_path, headers: true, encoding: 'BOM|UTF-8')
      expect(table.headers).to eq csv_header
      expect(table.size).to eq 2

      files = {}
      table.each do |row|
        files[row["ファイルID"].to_i] = row["エラー"]
      end
      expect(files[ss_file1.id]).to eq nil
      expect(files[ss_file2.id]).to eq nil
      expect(files[ss_file3.id]).to eq nil
      expect(files[ss_file4.id]).to eq nil
      expect(files[ss_file5.id]).to eq "file_ids にファイルが含まれていない"
      expect(files[ss_file6.id]).to eq "file_ids にファイルが含まれていない"

      item3.reload
      expect(item3.column_values[0].file_ids).to match_array []

      # fix
      repairer = Cms::FileRepair::Repairer.new
      repairer.fix_states(site1)
      table = CSV.read(repairer.csv_path, headers: true, encoding: 'BOM|UTF-8')
      expect(table.headers).to eq csv_header
      expect(table.size).to eq 2

      files = {}
      table.each do |row|
        files[row["ファイルID"].to_i] = row["エラー"]
      end
      expect(files[ss_file1.id]).to eq nil
      expect(files[ss_file2.id]).to eq nil
      expect(files[ss_file3.id]).to eq nil
      expect(files[ss_file4.id]).to eq nil
      expect(files[ss_file5.id]).to eq "file_ids にファイルが含まれていない"
      expect(files[ss_file6.id]).to eq "file_ids にファイルが含まれていない"

      item3.reload
      expect(item3.column_values[0].file_ids).to match_array [ss_file5.id, ss_file6.id]

      # check
      repairer = Cms::FileRepair::Repairer.new
      repairer.check_states(site1)
      table = CSV.read(repairer.csv_path, headers: true, encoding: 'BOM|UTF-8')
      expect(table.headers).to eq csv_header
      expect(table.size).to eq 0
    end
  end

  context "owner item reference another page (not fix)" do
    before do
      save_files

      item2.html = item1.html
      item2.update!

      value = item3.column_values[0]
      value.value = item1.html
      item3.column_values = [value]
      item3.update!
    end

    it do
      # check
      repairer = Cms::FileRepair::Repairer.new
      repairer.check_states(site1)
      table = CSV.read(repairer.csv_path, headers: true, encoding: 'BOM|UTF-8')
      expect(table.headers).to eq csv_header
      expect(table.size).to eq 4

      files = {}
      table.each do |row|
        files[row["ファイルID"].to_i] = row["エラー"]
      end

      expect(files[ss_file1.id]).to include("owner_item が別ページを参照している (#{item1.id})")
      expect(files[ss_file2.id]).to include("owner_item が別ページを参照している (#{item1.id})")
      expect(files[ss_file3.id]).to eq nil
      expect(files[ss_file4.id]).to eq nil
      expect(files[ss_file5.id]).to eq nil
      expect(files[ss_file6.id]).to eq nil

      ss_file1.reload
      ss_file2.reload
      expect(ss_file1.owner_item.id).to eq item1.id
      expect(ss_file2.owner_item.id).to eq item1.id

      # fix
      repairer = Cms::FileRepair::Repairer.new
      repairer.fix_states(site1)
      table = CSV.read(repairer.csv_path, headers: true, encoding: 'BOM|UTF-8')
      expect(table.headers).to eq csv_header
      expect(table.size).to eq 0

      ss_file1.reload
      ss_file2.reload
      expect(ss_file1.owner_item.id).to eq item1.id
      expect(ss_file2.owner_item.id).to eq item1.id

      # check
      repairer = Cms::FileRepair::Repairer.new
      repairer.check_states(site1)
      table = CSV.read(repairer.csv_path, headers: true, encoding: 'BOM|UTF-8')
      expect(table.headers).to eq csv_header
      expect(table.size).to eq 4

      files = {}
      table.each do |row|
        files[row["ファイルID"].to_i] = row["エラー"]
      end
      expect(files[ss_file1.id]).to include("owner_item が別ページを参照している (#{item1.id})")
      expect(files[ss_file2.id]).to include("owner_item が別ページを参照している (#{item1.id})")
      expect(files[ss_file3.id]).to eq nil
      expect(files[ss_file4.id]).to eq nil
      expect(files[ss_file5.id]).to eq nil
      expect(files[ss_file6.id]).to eq nil
    end
  end

  context "private file not found or empty (not fix)" do
    before do
      save_files

      ss_file1.destroy
      Fs.rm_rf(ss_file2.path)
      Fs.binwrite(ss_file3.path, "")
    end

    it do
      # check
      repairer = Cms::FileRepair::Repairer.new
      repairer.check_states(site1)
      table = CSV.read(repairer.csv_path, headers: true, encoding: 'BOM|UTF-8')
      expect(table.headers).to eq csv_header
      expect(table.size).to eq 3

      files = {}
      table.each do |row|
        files[row["ファイルID"].to_i] = row["エラー"]
      end

      expect(files[ss_file1.id]).to eq "ss_file が存在しない"
      expect(files[ss_file2.id]).to eq "private/files/ss_files ファイルが空"
      expect(files[ss_file3.id]).to eq "private/files/ss_files ファイルが空"
      expect(files[ss_file4.id]).to eq nil
      expect(files[ss_file5.id]).to eq nil
      expect(files[ss_file6.id]).to eq nil

      # fix
      repairer = Cms::FileRepair::Repairer.new
      repairer.fix_states(site1)
      table = CSV.read(repairer.csv_path, headers: true, encoding: 'BOM|UTF-8')
      expect(table.headers).to eq csv_header
      expect(table.size).to eq 0

      # check
      repairer = Cms::FileRepair::Repairer.new
      repairer.check_states(site1)
      table = CSV.read(repairer.csv_path, headers: true, encoding: 'BOM|UTF-8')
      expect(table.headers).to eq csv_header
      expect(table.size).to eq 3

      files = {}
      table.each do |row|
        files[row["ファイルID"].to_i] = row["エラー"]
      end
      expect(files[ss_file1.id]).to eq "ss_file が存在しない"
      expect(files[ss_file2.id]).to eq "private/files/ss_files ファイルが空"
      expect(files[ss_file3.id]).to eq "private/files/ss_files ファイルが空"
      expect(files[ss_file4.id]).to eq nil
      expect(files[ss_file5.id]).to eq nil
      expect(files[ss_file6.id]).to eq nil
    end
  end
end
