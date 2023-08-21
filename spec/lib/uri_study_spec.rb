require 'spec_helper'

describe Addressable::URI do
  xdescribe ".encode" do
    it do
      "ou=001001政策課,ou=001企画政策部,dc=example,dc=jp".tap do |dn|
        expect(URI.escape(dn)).to eq Addressable::URI.encode(dn)
      end

      "uid=user1,ou=001001政策課,ou=001企画政策部,dc=example,dc=jp".tap do |dn|
        expect(URI.escape(dn)).to eq Addressable::URI.encode(dn)
      end

      "https://www.ss-proj.org/".tap do |url|
        expect(URI.escape(url)).to eq Addressable::URI.encode(url)
      end

      "index - コピー.json".tap do |filename|
        expect(URI.escape(filename)).to eq Addressable::URI.encode(filename)
      end

      "https://www.ホスト.com/パス.html?クエリ=値#フラグメント".tap do |url|
        expect(URI.escape(url).sub("%23", "#")).to eq Addressable::URI.encode(url)
      end
    end
  end

  xdescribe ".encode_component" do
    it do
      "http://#{unique_domain}/#{unique_id}?a=b".tap do |url|
        expect(URI.escape(url, /[^0-9a-zA-Z]/n)).to eq Addressable::URI.encode_component(url, '0-9a-zA-Z')
      end

      # malformed url
      "http:/xyz/".tap do |url|
        expect(URI.escape(url, /[^0-9a-zA-Z]/n)).to eq Addressable::URI.encode_component(url, '0-9a-zA-Z')
      end
    end
  end

  xdescribe ".unencode" do
    it do
      "https://example.jp/bdd0fccc.jpg?h=200&amp;w=200&amp;pri=l".tap do |url|
        # puts URI.decode(url)
        # puts Addressable::URI.unencode(url)
        expect(URI.decode(url)).to eq Addressable::URI.unencode(url)
      end

      "//ja.m.wikipedia.org/wiki/%E3%83%A1%E3%82%A4%E3%83%B3%E3%83%9A%E3%83%BC%E3%82%B8".tap do |url|
        puts URI.decode(url)
        puts Addressable::URI.unencode(url)
        expect(URI.decode(url)).to eq Addressable::URI.unencode(url)
      end
    end
  end
end
