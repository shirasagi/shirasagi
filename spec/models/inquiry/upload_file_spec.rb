require 'spec_helper'

describe Inquiry::Answer, dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create :inquiry_node_form, cur_site: site }

  before do
    node.columns.create! attributes_for(:inquiry_column_upload_file).reverse_merge({cur_site: site})
    node.reload
  end

  let(:upload_file_column) { node.columns[0] }
  let(:data) { { upload_file_column.id => file } }

  # 1MB+ file
  let(:filename) { "#{unique_id}.txt" }
  let(:file) do
    f = Tempfile.open
    f.write ("a" * 1024 * 1024) + "b"
    f.rewind
    ActionDispatch::Http::UploadedFile.new(filename: filename, type: "text/csv",
      name: "item[in_file]", tempfile: f)
  end
  let(:error_message) do
    "#{upload_file_column.name}#{I18n.t(
      "errors.messages.too_large_file",
      filename: filename,
      size: ApplicationController.helpers.number_to_human_size((1 * 1024 * 1024) + 1),
      limit: ApplicationController.helpers.number_to_human_size((1 * 1024 * 1024)))}"
  end

  context "no limit" do
    before do
      upload_file_column.max_upload_file_size = 0
      upload_file_column.update!
    end

    it do
      item = described_class.new(cur_site: site, cur_node: node)
      item.set_data(data)

      expect(SS::File.where(site_id: site.id).count).to eq 1
      ss_file = SS::File.where(site_id: site.id).first

      expect(item.data.size).to eq 1
      expect(item.data[0].column_id).to eq upload_file_column.id
      expect(item.data[0].value).to eq ss_file.id.to_s
      expect(item.data[0].values[0]).to eq ss_file.id
      expect(item.data[0].values[1]).to eq ss_file.filename
      expect(item.data[0].values[2]).to eq ss_file.name
      expect(item.data[0].values[3]).to eq ss_file.size
      expect(item.data[0].values[3]).to eq ((1 * 1024 * 1024) + 1)
      expect(item.valid?).to be_truthy
    end
  end

  context "1mb limit" do
    before do
      upload_file_column.max_upload_file_size = 1
      upload_file_column.update!
    end

    it do
      item = described_class.new(cur_site: site, cur_node: node)
      item.set_data(data)

      expect(SS::File.where(site_id: site.id).count).to eq 1
      ss_file = SS::File.where(site_id: site.id).first

      expect(item.data.size).to eq 1
      expect(item.data[0].column_id).to eq upload_file_column.id
      expect(item.data[0].value).to eq ss_file.id.to_s
      expect(item.data[0].values[0]).to eq ss_file.id
      expect(item.data[0].values[1]).to eq ss_file.filename
      expect(item.data[0].values[2]).to eq ss_file.name
      expect(item.data[0].values[3]).to eq ss_file.size
      expect(item.data[0].values[3]).to eq ((1 * 1024 * 1024) + 1)
      expect(item.valid?).to be_falsey

      expect(item.errors.full_messages.size).to eq 1
      expect(item.errors.full_messages[0]).to eq error_message
    end
  end
end
