require 'spec_helper'

RSpec.describe Gws::Board::Post, type: :model, dbscope: :example do
  describe "mode and permit_comment field validations" do
    it { expect(build(:gws_board_topic,   mode: nil)          ).not_to be_valid }
    it { expect(build(:gws_board_comment, mode: nil)          ).to     be_valid }
    it { expect(build(:gws_board_topic,   permit_comment: nil)).not_to be_valid }
    it { expect(build(:gws_board_comment, permit_comment: nil)).to     be_valid }
  end
end
