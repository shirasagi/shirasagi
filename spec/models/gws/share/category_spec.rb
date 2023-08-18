require 'spec_helper'

describe Gws::Share::Category, type: :model, dbscope: :example do
  context "blank params" do
    subject { described_class.new.valid? }
    it { expect(subject).to be_falsey }
  end

  context "default params" do
    subject { create :gws_share_category }
    it { expect(subject.errors.size).to eq 0 }
  end

  context "renaming" do
    let!(:root) { create(:gws_share_category) }
    let!(:child) { create(:gws_share_category, name: "#{root.name}/#{unique_id}") }
    let!(:new_name) { unique_id }

    it do
      old_name = root.name
      expect(child.name).to start_with("#{old_name}/")

      root.name = new_name
      root.save!

      child.reload
      expect(child.name).not_to start_with("#{old_name}/")
      expect(child.name).to start_with(new_name)
    end
  end

  describe ".tree_sort" do
    before do
      create(:gws_share_category, name: 'A')
      create(:gws_share_category, name: 'A/AA', order: 100)
      create(:gws_share_category, name: 'B')
      create(:gws_share_category, name: 'B/BB')
    end

    subject { described_class.all.tree_sort.to_a }

    it do
      expect(subject.count).to eq 4

      subject[0].tap do |category|
        expect(category.name).to eq 'A'
        expect(category.depth).to eq 0
        expect(category.trailing_name).to eq 'A'
      end

      subject[1].tap do |category|
        expect(category.name).to eq 'A/AA'
        expect(category.depth).to eq 1
        expect(category.trailing_name).to eq 'AA'
      end

      subject[2].tap do |category|
        expect(category.name).to eq 'B'
        expect(category.depth).to eq 0
        expect(category.trailing_name).to eq 'B'
      end

      subject[3].tap do |category|
        expect(category.name).to eq 'B/BB'
        expect(category.depth).to eq 1
        expect(category.trailing_name).to eq 'BB'
      end
    end
  end

  describe ".to_options" do
    before do
      create(:gws_share_category, name: 'A')
      create(:gws_share_category, name: 'A/AA', order: 100)
      create(:gws_share_category, name: 'B')
      create(:gws_share_category, name: 'B/BB')
    end

    subject { described_class.all.tree_sort.to_options }

    it do
      subject[0].tap do |category|
        expect(category[0]).to eq 'A'
        expect(category[1]).to eq 1
      end

      subject[1].tap do |category|
        expect(category[0]).to eq '+---- AA'
        expect(category[1]).to eq 2
      end

      subject[2].tap do |category|
        expect(category[0]).to eq 'B'
        expect(category[1]).to eq 3
      end

      subject[3].tap do |category|
        expect(category[0]).to eq '+---- BB'
        expect(category[1]).to eq 4
      end
    end
  end
end
