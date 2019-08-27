require 'spec_helper'

describe History::Trash do
  subject(:model) { described_class }
  subject(:factory) { :history_trash }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"

  context 'when destroy nodes that same filename' do
    it "restore" do
      expect(described_class.count).to eq 1

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

      expect(described_class.count).to eq 5
    end
  end
end
