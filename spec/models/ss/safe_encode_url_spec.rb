require 'spec_helper'

describe SS, dbscope: :example do
  describe ".safe_encode_url" do
    context "with valid url" do
      it do
        expect(SS.safe_encode_url("https://example.jp/")).to eq "https://example.jp/"
      end
    end

    context "with valid path" do
      it do
        expect(SS.safe_encode_url("/docs/page1.html")).to eq "/docs/page1.html"
      end
    end

    context "with fragment" do
      it do
        expect(SS.safe_encode_url("https://example.jp/#fragment")).to eq "https://example.jp/#fragment"
      end
    end

    context "with query" do
      it do
        url = "https://www.google.com/search?q=%E3%82%A8%E3%83%B3%E3%82%B3%E3%83%BC%E3%83%89"
        expect(SS.safe_encode_url(url)).to eq url
      end
    end

    context "with invalid url #1" do
      it do
        expect(SS.safe_encode_url("http://example.jp /")).to eq "http://example.jp /"
      end
    end

    context "with invalid url #2" do
      it do
        expect(SS.safe_encode_url("https://example.jp /")).to eq "https://example.jp /"
      end
    end

    context "with scheme 'javascript'" do
      it do
        expect(SS.safe_encode_url("javascript:alert('test')")).to eq "javascript:alert('test')"
      end
    end

    context "with 日本語 in path" do
      it do
        expect(SS.safe_encode_url("https://www.example.jp/日本語")).to eq "https://www.example.jp/%E6%97%A5%E6%9C%AC%E8%AA%9E"
      end
    end

    context "with 日本語 path" do
      it do
        expect(SS.safe_encode_url("/日本語")).to eq "/%E6%97%A5%E6%9C%AC%E8%AA%9E"
      end
    end

    context "with vulnerable path" do
      it do
        expect(SS.safe_encode_url(%(/x" onclick="alert(1)"))).to eq "/x%22%20onclick=%22alert(1)%22"
      end
    end

    context "with already encoded url" do
      it do
        origin = url = "https://www.example.jp/%E6%97%A5%E6%9C%AC%E8%AA%9E"
        3.times do
          url = SS.safe_encode_url(url)
        end
        expect(url).to eq origin
      end
    end

    context "with already encoded path" do
      it do
        origin = path = "/%E6%97%A5%E6%9C%AC%E8%AA%9E"
        3.times do
          path = SS.safe_encode_url(path)
        end
        expect(path).to eq origin
      end
    end
  end
end
