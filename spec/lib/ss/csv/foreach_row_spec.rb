require 'spec_helper'

describe SS::Csv do
  let(:csv_file) { "#{Rails.root}/spec/fixtures/article/article_import_test_1.csv" }

  shared_examples "what SS::Csv#foreach_row is" do
    context "when given block accepts no arguments" do
      it do
        count = 0
        described_class.foreach_row(param) do
          count += 1
        end
        expect(count).to eq 2
      end
    end

    context "when given block accepts 1 argument" do
      it do
        count = 0
        described_class.foreach_row(param) do |row|
          expect(row).to be_present
          count += 1
        end
        expect(count).to eq 2
      end
    end

    context "when given block accepts 2 argument" do
      it do
        count = 0
        described_class.foreach_row(param) do |row, index|
          expect(row).to be_present
          expect(index).to eq count
          count += 1
        end
        expect(count).to eq 2
      end
    end

    context "when headers is true" do
      it do
        count = 0
        described_class.foreach_row(param, headers: true) do
          count += 1
        end
        expect(count).to eq 2
      end
    end

    context "when headers is false" do
      it do
        count = 0
        described_class.foreach_row(param, headers: false) do
          count += 1
        end
        expect(count).to eq 3
      end
    end
  end

  context "path is given" do
    let(:param) { csv_file }

    it_behaves_like "what SS::Csv#foreach_row is"
  end

  context "ss/file is given" do
    let(:param) { tmp_ss_file(contents: csv_file) }

    it_behaves_like "what SS::Csv#foreach_row is"
  end

  context "io is given" do
    let(:param) { File.open(csv_file) }

    it_behaves_like "what SS::Csv#foreach_row is"

    after do
      param.close
    end
  end
end
