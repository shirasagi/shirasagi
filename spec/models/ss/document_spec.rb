require 'spec_helper'

RSpec.describe SS::Document, type: :model, dbscope: :example do
  class Klass
    include SS::Document

    field :name, type: String
  end

  describe "#created and #updated" do
    it do
      Timecop.scale(1_000_000_000)
      object = Klass.new
      expect(object.created == object.updated).to be_truthy
      Timecop.return
    end
  end

  describe ".keyword_in" do
    context "check logical side" do
      let(:words) { "名|前 な(*.?)まえ" }
      let(:fields) { [ "name" ] }
      subject { Klass.keyword_in(words, *fields).selector.to_h }

      it do
        expect(subject).to include("$and" => include("$or" => include("name" => /名\|前/i)))
        expect(subject).to include("$and" => include("$or" => include("name" => /な\(\*\.\?\)まえ/i)))
      end
    end

    context "check effective side" do
      let!(:item) { Klass.create! name: "名|前 な(*.?)まえ" }

      it do
        expect(Klass.keyword_in("名|前", "name").first._id).to eq item._id
      end

      it do
        expect(Klass.keyword_in("な", "name").first._id).to eq item._id
      end

      it do
        expect(Klass.keyword_in("名|前 な(*.?)まえ", "name").first._id).to eq item._id
      end
    end
  end

  describe ".search_text" do
    context "check logical side" do
      let(:words) { "名|前 な(*.?)まえ" }
      subject { Klass.search_text(words).selector.to_h }

      it do
        expect(subject).to include("name" => include("$all" => include(/名\|前/i, /な\(\*\.\?\)まえ/i)))
      end
    end

    context "check effective side" do
      let!(:item) { Klass.create! name: "名|前 な(*.?)まえ" }

      it do
        expect(Klass.search_text("名|前").first._id).to eq item._id
      end

      it do
        expect(Klass.search_text("な").first._id).to eq item._id
      end

      it do
        expect(Klass.search_text("名|前 な(*.?)まえ").first._id).to eq item._id
      end
    end
  end
end
