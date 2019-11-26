require 'spec_helper'

describe Board::Post, type: :model, dbscope: :example do
  describe "validation" do
    let(:node) { create :board_node_post }
    let(:item) { create :board_post, cur_node: node}
    let(:child_item) { create(:board_post, node: node, topic_id: item.id, parent_id: item.parent_id) }

    it "presence_validation" do
      expect(item.valid?).to be_truthy
      expect(child_item.valid?).to be_truthy
    end

    context "when 3 chars is for delete_key" do
      before do
        item.delete_key = "out"
      end

      it do
        expect(item.invalid?).to be_truthy
        expect(item.errors.messages[:delete_key]).to include(I18n.t('board.errors.invalid_delete_key'))
      end
    end
  end
end