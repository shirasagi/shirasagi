require 'spec_helper'

describe History::Trash do
  subject(:model) { described_class }
  subject(:factory) { :history_trash }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"

  context 'when destroy nodes that same filename' do
    before { described_class.all.destroy }

    it "restore" do
      node = build(:cms_node, filename: 'node-trash')
      node.save
      page = build(:cms_page, filename: 'node-trash/page-trash')
      page.save
      node.destroy

      node = build(:cms_node, filename: 'node-trash')
      node.save
      page = build(:cms_page, filename: 'node-trash/page-trash')
      page.save
      node.destroy

      expect(described_class.count).to eq 4
    end
  end

  context 'when destroy pages with file' do
    let(:file) { create :ss_file, user_id: cms_user.id }
    let(:item) { create(:cms_page, file_ids: [file.id]) }
    before { described_class.all.destroy }

    it "restore" do
      item.destroy
      expect(File.exists?("#{described_class.root}/#{file.path.sub(/.*\/(ss_files\/)/, '\\1')}")).to be_truthy

      described_class.all.destroy_all
      expect(File.exists?("#{described_class.root}/#{file.path.sub(/.*\/(ss_files\/)/, '\\1')}")).to be_falsey
    end
  end
end
