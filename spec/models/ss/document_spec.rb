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

  describe ".find_in_batches" do
    before do
      1.upto(10) do
        Klass.create!(name: unique_id)
      end
    end

    context "when block is given" do
      it do
        total_count = 0
        check = {}
        Klass.find_in_batches(batch_size: 3) do |records|
          total_count += records.size
          records.each do |r|
            expect(check[r.name]).to be_nil
            check[r.name] = true
          end
        end
        expect(total_count).to eq Klass.count
      end
    end

    context "when block and offset is given" do
      it do
        total_count = 0
        check = {}
        Klass.find_in_batches(offset: Klass.count / 2, batch_size: 3) do |records|
          total_count += records.size
          records.each do |r|
            expect(check[r.name]).to be_nil
            check[r.name] = true
          end
        end
        expect(total_count).to eq Klass.count / 2
      end
    end

    context "when block is not given" do
      it do
        enum = Klass.find_in_batches(batch_size: 3)

        total_count = 0
        check = {}
        enum.each do |records|
          total_count += records.size
          records.each do |r|
            expect(check[r.name]).to be_nil
            check[r.name] = true
          end
        end
        expect(total_count).to eq Klass.count
      end
    end
  end

  describe ".find_each" do
    before do
      1.upto(10) do
        Klass.create!(name: unique_id)
      end
    end

    context "when block is given" do
      it do
        total_count = 0
        check = {}
        Klass.find_each(batch_size: 3) do |r|
          total_count += 1
          expect(check[r.name]).to be_nil
          check[r.name] = true
        end
        expect(total_count).to eq Klass.count
      end
    end

    context "when block and offset is given" do
      it do
        total_count = 0
        check = {}
        Klass.find_each(offset: Klass.count / 2, batch_size: 3) do |r|
          total_count += 1
          expect(check[r.name]).to be_nil
          check[r.name] = true
        end
        expect(total_count).to eq Klass.count / 2
      end
    end

    context "when block is not given" do
      it do
        enum = Klass.find_each(batch_size: 3)

        total_count = 0
        check = {}
        enum.each do |r|
          total_count += 1
          expect(check[r.name]).to be_nil
          check[r.name] = true
        end
        expect(total_count).to eq Klass.count
      end
    end
  end
end
