require 'spec_helper'

RSpec.describe Gws::Board::Post, type: :model, dbscope: :example do
  describe "topic scope" do
    subject { described_class.topic }
    let!(:topic) { create :gws_board_topic }
    let!(:comment) { create :gws_board_comment }
    it { is_expected.to include(topic) }
    it { is_expected.not_to include(comment) }
  end
end
