require 'spec_helper'

describe Kana::Dictionary do
  subject(:model) { Kana::Dictionary }
  subject(:factory) { :kana_dictionary }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"

  context "with item" do
    subject(:item) { create(:kana_dictionary) }

    describe "#validate_body" do
      it "has no error" do
        expect(item.validate_body).to be true
        expect(item.errors.blank?).to be true
      end
    end

    describe "#enumerate_csv" do
      it "has at least one item and word and yomi is valid" do
        count = 0
        item.enumerate_csv.each do |word, yomi|
          expect(word).to_not be_empty
          expect(yomi).to_not be_empty
          count += 1
        end
        expect(count).to be >= 1
      end
    end

    describe "#master_root" do
      it "returns full path" do
        expect(model.master_root).to eq File.expand_path(model.master_root, Rails.root)
      end
    end

    describe "#master_dic" do
      it "contains site_id" do
        expect(model.master_dic(1)).to include("/1/")
      end

      it "ends with '/_/user.dic'" do
        expect(model.master_dic(1)).to end_with("/_/user.dic")
      end
    end

    describe("#build_dic and #pull", mecab: true) do
      it "builds user dictionary" do
        # before build, ensure that dictionary file is not existed.
        user_dic = model.master_dic(item.site_id)
        Fs.rm_rf(user_dic) if Fs.exists?(user_dic)

        model.build_dic(item.site_id)
        expect(Fs.exists?(user_dic)).to be true
      end

      it "can pull user dictionary" do
        model.pull(item.site_id) do |userdic|
          expect(userdic).to_not be nil
        end
      end
    end

    describe "#search" do
      it "returns empty criteria if nil is given" do
        criteria = model.search(nil)
        expect(criteria).to_not be nil
        # how are we able to test criteria's selector?
      end

      it "returns empty criteria if name is given" do
        criteria = model.search(name: "name")
        expect(criteria).to_not be nil
      end

      it "returns field_list when keyword is given" do
        criteria = model.search(keyword: "keyword")
        expect(criteria).to_not be nil
      end
    end
  end

  context "with_error item" do
    subject(:item) { build(:kana_dictionary_with_3_errors) }

    describe "#validate_body" do
      it "has 3 errors" do
        expect(item.validate_body).to be false
        expect(item.errors.count).to eq 3
      end

      it "fails to save" do
        expect { item.save! }.to raise_error
      end
    end

    describe "#enumerate_csv" do
      it "has at least one item" do
        expect(item.enumerate_csv.count).to be >= 1
      end

      it "yields only valid word and yomi" do
        item.enumerate_csv.each do |word, yomi|
          expect(word).to_not be_empty
          expect(yomi).to_not be_empty
        end
      end
    end
  end
end
