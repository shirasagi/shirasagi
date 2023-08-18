require 'spec_helper'

RSpec.describe Gws::Board::Post, type: :model, dbscope: :example do
  describe "topic scope" do
    subject { described_class.topic }
    let!(:topic) { create :gws_board_topic }
    let!(:comment) { create :gws_board_comment }
    it { expect(subject.pluck(:id)).to include(topic.id) }
    it { expect(subject.pluck(:id)).not_to include(comment.id) }
  end
end
