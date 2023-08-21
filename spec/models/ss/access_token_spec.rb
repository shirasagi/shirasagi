require 'spec_helper'

describe SS::AccessToken do
  describe ".remove_access_token_from_query" do
    context "when only access_token is given" do
      let(:url) { "https://www.example.jp/page.html?access_token=#{described_class.new_token}" }
      subject { described_class.remove_access_token_from_query(url) }

      it do
        expect(subject).to eq "https://www.example.jp/page.html"
      end
    end

    context "when access_token is put on the first" do
      let(:url) { "https://www.example.jp/page.html?access_token=#{described_class.new_token}&key1=value1&key2=value2" }
      subject { described_class.remove_access_token_from_query(url) }

      it do
        expect(subject).to eq "https://www.example.jp/page.html?key1=value1&key2=value2"
      end
    end

    context "when access_token is put on the last" do
      let(:url) { "https://www.example.jp/page.html?key1=value1&key2=value2&access_token=#{described_class.new_token}" }
      subject { described_class.remove_access_token_from_query(url) }

      it do
        expect(subject).to eq "https://www.example.jp/page.html?key1=value1&key2=value2"
      end
    end

    context "when access_token is put on a middle of query parameters" do
      let(:url) { "https://www.example.jp/page.html?key1=value1&access_token=#{described_class.new_token}&key2=value2" }
      subject { described_class.remove_access_token_from_query(url) }

      it do
        expect(subject).to eq "https://www.example.jp/page.html?key1=value1&key2=value2"
      end
    end
  end
end
