require 'spec_helper'

describe Gws::UserTitle, type: :model, dbscope: :example do
  let(:model) { described_class }

  describe "validation" do
    it { expect(model.new.save).to be_falsey }
  end

  describe "factory" do
    subject { create :gws_user_title }
    its(:name) { is_expected.not_to be_nil }
    its(:order) { is_expected.not_to be_nil }
    its(:valid?) { is_expected.to be_truthy }
  end

  describe "title and its order" do
    let(:title1) { create :gws_user_title }
    let(:title2) { create :gws_user_title, order: title1.order + 10 }
    let!(:user1) { create :gws_user, in_title_id: title1.id }
    let!(:user2) { create :gws_user, in_title_id: title2.id }

    it "initial title order" do
      user1.reload
      user2.reload
      expect(user1.title_orders[title1.group_id.to_s]).to eq title1.order
      expect(user2.title_orders[title2.group_id.to_s]).to eq title2.order
    end

    it "change title's order" do
      title1.order = title1.order - 10
      expect(title1.save).to be_truthy

      user1.reload
      user2.reload
      expect(user1.title_orders[title1.group_id.to_s]).to eq title1.order
      expect(user2.title_orders[title2.group_id.to_s]).to eq title2.order
    end

    it "change user's title" do
      user1.in_title_id = title2.id
      user1.save

      expect(user1.title_orders[title1.group_id.to_s]).not_to eq title1.order
      expect(user1.title_orders[title2.group_id.to_s]).to eq title2.order
    end

    it "remove user's title" do
      user1.in_title_id = ""
      user1.save

      expect(user1.title_ids).to eq []
      expect(user1.title_orders[title1.group_id.to_s]).to be_nil
    end
  end
end
