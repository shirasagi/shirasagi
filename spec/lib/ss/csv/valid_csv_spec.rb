require 'spec_helper'

describe SS::Csv do
  context "with non-existing file" do
    it do
      expect(described_class.valid_csv?("#{Rails.root}/tmp/#{unique_id}.csv")).to be_falsey
    end
  end

  context "with existing file" do
    let(:csv_file) { "#{Rails.root}/spec/fixtures/article/article_import_test_1.csv" }

    context "without required_headers" do
      it do
        expect(described_class.valid_csv?(csv_file)).to be_truthy
      end
    end

    context "with valid required_headers" do
      let(:required_headers) do
        [ Article::Page.t(:name) ]
      end

      it do
        expect(described_class.valid_csv?(csv_file, required_headers: required_headers)).to be_truthy
      end
    end

    context "with invalid required_headers" do
      let(:required_headers) do
        [ Gws::Schedule::Plan.t(:term) ]
      end

      it do
        expect(described_class.valid_csv?(csv_file, required_headers: required_headers)).to be_falsey
      end
    end
  end
end
