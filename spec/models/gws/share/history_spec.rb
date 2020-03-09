require 'spec_helper'

RSpec.describe Gws::Share::History, type: :model, dbscope: :example do
  describe ".item" do
    let!(:file) { create :gws_share_file }
    subject { file.histories.first }

    context "with file" do
      it do
        expect(subject.item).to eq file
      end
    end

    context "without file" do
      before do
        file.delete
      end

      it do
        expect(subject.item).to be_nil
      end
    end
  end

  describe ".path" do
    let!(:file) { create :gws_share_file }
    subject { file.histories.first }

    context "with file" do
      it do
        expect(subject.path).to eq "#{file.path}_history0"
      end
    end

    context "without file" do
      before do
        file.delete
      end

      it do
        expect(subject.path).to be_nil
      end
    end
  end

  describe ".destroy_history_file" do
    let!(:file) { create :gws_share_file }

    context "when delete history file on destroying all referenced histories" do
      before do
        file.in_file = nil
        file.name = unique_id
        file.save!

        expect(file.histories.count).to eq 2
        expect(file.histories.map(&:path).all? { |path| path == "#{file.path}_history0" }).to be_truthy
      end

      it do
        histories = file.histories.to_a
        history0 = histories[0]
        history1 = histories[1]

        history1.destroy
        expect(::Fs.exists?(history0.path)).to be_truthy

        history0.destroy
        expect(::Fs.exists?(history0.path)).to be_falsey
      end
    end
  end
end

