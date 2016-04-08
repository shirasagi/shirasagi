require 'spec_helper'

describe Gws::Board::Category, type: :model, dbscope: :example do
  context "blank params" do
    subject { described_class.new.valid? }
    it { expect(subject).to be_falsey }
  end

  context "default params" do
    subject { create :gws_board_category }
    it { expect(subject.errors.size).to eq 0 }
  end

  context "renaming" do
    let!(:root) { create(:gws_board_category) }
    let!(:child) { create(:gws_board_category, name: "#{root.name}/#{unique_id}") }
    let!(:new_name) { unique_id }

    it do
      old_name = root.name
      expect(child.name).to start_with("#{old_name}/")

      root.name = new_name
      root.save!

      child.reload
      expect(child.name).not_to start_with("#{old_name}/")
      expect(child.name).to start_with("#{new_name}")
    end
  end
end
