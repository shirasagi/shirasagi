require 'spec_helper'

RSpec.describe SS::Document, type: :model, dbscope: :example do
  class Klass
    include SS::Document

    field :name, type: String
    field :bool1, type: Boolean
    field :bool2, type: Boolean, default: false
    field :bool3, type: Boolean, default: -> { false }
    field :str1, type: String
    field :str2, type: String, default: ""
    field :str3, type: String, default: -> { "" }, metadata: { normalize: false }
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

  describe "boolean field normalization" do
    before do
      @name = unique_id
      Klass.create!(name: @name, bool1: false, bool2: false, bool3: false)
    end

    it do
      # bool1 field was not removed because bool1 is boolean.
      expect(Klass.where(bool1: false).count).to eq 1
    end

    it do
      # bool2 field was not removed because bool2 has default.
      expect(Klass.where(bool2: false).count).to eq 1
    end

    it do
      # bool3 field was not removed because bool3 has default.
      expect(Klass.where(bool3: false).count).to eq 1
    end
  end

  describe "string field normalization" do
    context "when blank string is given" do
      before do
        @name = unique_id
        Klass.create!(name: @name, str1: "", str2: "", str3: "")
      end

      it do
        # str1 field was removed by SS::Fields::Normalizer#remove_blank_fields
        expect(Klass.where(str1: "").count).to eq 0
        expect(Klass.where(:str1.exists => false).count).to eq 1
      end

      it do
        # str2 field was not removed because str2 has default.
        expect(Klass.where(str2: "").count).to eq 1
      end

      it do
        # str3 field was not removed because str3 has default.
        expect(Klass.where(str3: "").count).to eq 1
      end
    end

    context "when 1-space-string is given" do
      before do
        @name = unique_id
        Klass.create!(name: @name, str1: " ", str2: " ", str3: " ")
      end

      it do
        # str1 field was not stripped because str1 length is 1
        expect(Klass.where(str1: /^ $/).count).to eq 1
      end

      it do
        # str2 field was not stripped because str2 length is 1
        expect(Klass.where(str2: /^ $/).count).to eq 1
      end

      it do
        # str3 field was not stripped because str3 length is 1
        expect(Klass.where(str3: /^ $/).count).to eq 1
      end
    end

    context "when leading spaces/trailing spaces is given" do
      before do
        @name = unique_id
        @str = " \r\n\t aaa \r\n\t "
        Klass.create!(name: @name, str1: @str, str2: @str, str3: @str)
      end

      it do
        # str1 field was stripped
        expect(Klass.where(str1: /^#{Regexp.escape(@str)}$/).count).to eq 0
        expect(Klass.where(str1: /^#{Regexp.escape(@str.strip)}$/).count).to eq 1
      end

      it do
        # str2 field was stripped
        expect(Klass.where(str2: /^#{Regexp.escape(@str)}$/).count).to eq 0
        expect(Klass.where(str2: /^#{Regexp.escape(@str.strip)}$/).count).to eq 1
      end

      it do
        # str3 field was not stripped because str3 has metadata: { normalize: false }
        expect(Klass.where(str3: /^#{Regexp.escape(@str)}$/).count).to eq 1
        expect(Klass.where(str3: /^#{Regexp.escape(@str.strip)}$/).count).to eq 0
      end
    end
  end
end
