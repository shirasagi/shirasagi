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

    context "with partially encoded url case1" do
      it do
        expect(SS.safe_encode_url("https://example.test/a%20b/c d")).to eq "https://example.test/a%20b/c%20d"
      end
    end

    context "with partially encoded url case2" do
      it do
        expect(SS.safe_encode_url("https://example.test/a%3Fb")).to eq "https://example.test/a%3Fb"
      end
    end

    context "code '%2F' ('/') within path" do
      it do
        # 基本戦略として全体を一度デコードしてからエンコードする。このような基本戦略のため、ケアすべき特別な状況がある。
        # パス内の '%2F' ('/') はデコードせずにそのままにしなければ意味が変わってしまう。
        expect(SS.safe_encode_url("https://example.test/files/a%2Fb")).to eq "https://example.test/files/a%2Fb"
        expect(SS.safe_encode_url("/files/a%2Fb")).to eq "/files/a%2Fb"
      end
    end

    context "code '%3F' ('?') within path" do
      it do
        # 基本戦略として全体を一度デコードしてからエンコードする。このような基本戦略のため、ケアすべき特別な状況がある。
        # パス内の '%3F' ('?') はデコードせずにそのままにしなければ意味が変わってしまう。
        expect(SS.safe_encode_url("https://example.test/files/a%3Fb")).to eq "https://example.test/files/a%3Fb"
        expect(SS.safe_encode_url("/files/a%3Fb")).to eq "/files/a%3Fb"
      end
    end

    context "code '%23' ('#') within path" do
      it do
        # 基本戦略として全体を一度デコードしてからエンコードする。このような基本戦略のため、ケアすべき特別な状況がある。
        # パス内の '%23' ('#') はデコードせずにそのままにしなければ意味が変わってしまう。
        expect(SS.safe_encode_url("https://example.test/files/a%23b")).to eq "https://example.test/files/a%23b"
        expect(SS.safe_encode_url("/files/a%23b")).to eq "/files/a%23b"
      end
    end

    context "code '%26' ('&') within query" do
      it do
        # 基本戦略として全体を一度デコードしてからエンコードする。このような基本戦略のため、ケアすべき特別な状況がある。
        # クエリ内の '%26' ('&') はデコードせずにそのままにしなければ意味が変わってしまう。
        expect(SS.safe_encode_url("https://example.test/files?a%26b=c")).to eq "https://example.test/files?a%26b=c"
        expect(SS.safe_encode_url("https://example.test/files?a%26b")).to eq "https://example.test/files?a%26b"
        expect(SS.safe_encode_url("https://example.test/files?a%26b=c")).to eq "https://example.test/files?a%26b=c"
        expect(SS.safe_encode_url("/files?a%26b=c")).to eq "/files?a%26b=c"
        expect(SS.safe_encode_url("/files?a%26b")).to eq "/files?a%26b"
      end
    end

    context "code '%40' ('@') within authority" do
      it do
        # 基本戦略として全体を一度デコードしてからエンコードする。このような基本戦略のため、ケアすべき特別な状況がある。
        # オーソリティ内の '%40' ('@') はデコードせずにそのままにしなければ意味が変わってしまう。
        expect(SS.safe_encode_url("https://user@example.test/files")).to eq "https://user@example.test/files"
        expect(SS.safe_encode_url("https://user%40example.test@example.test/files")).to eq "https://user%40example.test@example.test/files"
      end
    end

    context "invalid %" do
      it do
        expect(SS.safe_encode_url("https://example.jp/100%off")).to eq "https://example.jp/100%25off"
      end
    end

    context "with ldap://" do
      it do
        url = "ldap://ldap.example.com/dc=example,dc=com"
        expect(SS.safe_encode_url(url)).to eq url

        url = "ldap://ldap.example.com/dc=example,dc=com?postalAddress"
        expect(SS.safe_encode_url(url)).to eq url

        url = "ldap://ldap.example.com/cn=Barbara Jensen,dc=example,dc=com?cn,mail,telephoneNumber"
        expected = "ldap://ldap.example.com/cn=Barbara%20Jensen,dc=example,dc=com?cn,mail,telephoneNumber"
        expect(SS.safe_encode_url(url)).to eq expected
      end
    end
  end
end
