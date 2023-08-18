require 'spec_helper'

RSpec.describe Gws::Board::Post, type: :model, dbscope: :example do
  describe "#comment?" do
    it { expect(build(:gws_board_topic).comment?).to be_falsy }
    it { expect(build(:gws_board_comment).comment?).to be_truthy }
  end
end
