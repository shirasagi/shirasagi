require 'spec_helper'

describe SS, dbscope: :example do
  describe ".follow_up_url_encode" do
    context "with valid url" do
      it do
        expect(SS.follow_up_url_encode!("https://example.jp/")).to eq "https://example.jp/"
      end
    end

    context "with valid path" do
      it do
        expect(SS.follow_up_url_encode!("/docs/page1.html")).to eq "/docs/page1.html"
      end
    end

    context "with fragment" do
      it do
        expect(SS.follow_up_url_encode!("https://example.jp/#fragment")).to eq "https://example.jp/#fragment"
      end
    end

    context "with query" do
      it do
        url = "https://www.google.com/search?q=%E3%82%A8%E3%83%B3%E3%82%B3%E3%83%BC%E3%83%89"
        expect(SS.follow_up_url_encode!(url)).to eq url
      end
    end

    context "with invalid url #1" do
      it do
        expect { SS.follow_up_url_encode!("http://example.jp /") }.to raise_error Addressable::URI::InvalidURIError
      end
    end

    context "with invalid url #2" do
      it do
        expect { SS.follow_up_url_encode!("https://example.jp /") }.to raise_error Addressable::URI::InvalidURIError
      end
    end

    context "with scheme 'javascript'" do
      it do
        expect(SS.follow_up_url_encode!("javascript:alert('test')")).to eq "javascript:alert('test')"
      end
    end

    context "with 日本語 in path" do
      it do
        expect(SS.follow_up_url_encode!("https://www.example.jp/日本語")).to eq "https://www.example.jp/%E6%97%A5%E6%9C%AC%E8%AA%9E"
      end
    end

    context "with 日本語 path" do
      it do
        expect(SS.follow_up_url_encode!("/日本語")).to eq "/%E6%97%A5%E6%9C%AC%E8%AA%9E"
      end
    end

    context "with vulnerable path" do
      it do
        expect(SS.follow_up_url_encode!(%(/x" onclick="alert(1)"))).to eq "/x%22%20onclick=%22alert(1)%22"
      end
    end

    context "with already encoded url" do
      it do
        origin = url = "https://www.example.jp/%E6%97%A5%E6%9C%AC%E8%AA%9E"
        3.times do
          url = SS.follow_up_url_encode!(url)
        end
        expect(url).to eq origin
      end
    end

    context "with already encoded path" do
      it do
        origin = path = "/%E6%97%A5%E6%9C%AC%E8%AA%9E"
        3.times do
          path = SS.follow_up_url_encode!(path)
        end
        expect(path).to eq origin
      end
    end

    context "with partially encoded url case1" do
      it do
        expect(SS.follow_up_url_encode!("https://example.test/a%20b/c d")).to eq "https://example.test/a%20b/c%20d"
      end
    end

    context "with partially encoded url case2" do
      it do
        expect(SS.follow_up_url_encode!("https://example.test/a%3Fb")).to eq "https://example.test/a%3Fb"
      end
    end

    context "code '%2F' ('/') within path" do
      it do
        # 基本戦略として全体を一度デコードしてからエンコードする。このような基本戦略のため、ケアすべき特別な状況がある。
        # パス内の '%2F' ('/') はデコードせずにそのままにしなければ意味が変わってしまう。
        expect(SS.follow_up_url_encode!("https://example.test/files/a%2Fb")).to eq "https://example.test/files/a%2Fb"
        expect(SS.follow_up_url_encode!("/files/a%2Fb")).to eq "/files/a%2Fb"
      end
    end

    context "code '%3F' ('?') within path" do
      it do
        # 基本戦略として全体を一度デコードしてからエンコードする。このような基本戦略のため、ケアすべき特別な状況がある。
        # パス内の '%3F' ('?') はデコードせずにそのままにしなければ意味が変わってしまう。
        expect(SS.follow_up_url_encode!("https://example.test/files/a%3Fb")).to eq "https://example.test/files/a%3Fb"
        expect(SS.follow_up_url_encode!("/files/a%3Fb")).to eq "/files/a%3Fb"
      end
    end

    context "code '%23' ('#') within path" do
      it do
        # 基本戦略として全体を一度デコードしてからエンコードする。このような基本戦略のため、ケアすべき特別な状況がある。
        # パス内の '%23' ('#') はデコードせずにそのままにしなければ意味が変わってしまう。
        expect(SS.follow_up_url_encode!("https://example.test/files/a%23b")).to eq "https://example.test/files/a%23b"
        expect(SS.follow_up_url_encode!("/files/a%23b")).to eq "/files/a%23b"
      end
    end

    context "code '%26' ('&') within query" do
      it do
        # 基本戦略として全体を一度デコードしてからエンコードする。このような基本戦略のため、ケアすべき特別な状況がある。
        # クエリ内の '%26' ('&') はデコードせずにそのままにしなければ意味が変わってしまう。
        expect(SS.follow_up_url_encode!("https://example.test/files?a%26b=c")).to eq "https://example.test/files?a%26b=c"
        expect(SS.follow_up_url_encode!("https://example.test/files?a%26b")).to eq "https://example.test/files?a%26b"
        expect(SS.follow_up_url_encode!("https://example.test/files?a%26b=c")).to eq "https://example.test/files?a%26b=c"
        expect(SS.follow_up_url_encode!("/files?a%26b=c")).to eq "/files?a%26b=c"
        expect(SS.follow_up_url_encode!("/files?a%26b")).to eq "/files?a%26b"
      end
    end

    context "code '%40' ('@') within authority" do
      it do
        # 基本戦略として全体を一度デコードしてからエンコードする。このような基本戦略のため、ケアすべき特別な状況がある。
        # オーソリティ内の '%40' ('@') はデコードせずにそのままにしなければ意味が変わってしまう。
        expect(SS.follow_up_url_encode!("https://user@example.test/files")).to eq "https://user@example.test/files"
        expect(SS.follow_up_url_encode!("https://user%40example.test@example.test/files")).to eq "https://user%40example.test@example.test/files"
      end
    end

    context "invalid %" do
      it do
        expect(SS.follow_up_url_encode!("https://example.jp/100%off")).to eq "https://example.jp/100%25off"
      end
    end

    context "backslash" do
      it do
        expect(SS.follow_up_url_encode!("https://example.jp/a\\b")).to eq "https://example.jp/a%5Cb"
      end
    end

    context "line break" do
      it do
        expect(SS.follow_up_url_encode!(%(https://example.jp/a\nb))).to eq "https://example.jp/a%0Ab"
      end
    end

    context "with ldap://" do
      it do
        url = "ldap://ldap.example.com/dc=example,dc=com"
        expect(SS.follow_up_url_encode!(url)).to eq url

        url = "ldap://ldap.example.com/dc=example,dc=com?postalAddress"
        expect(SS.follow_up_url_encode!(url)).to eq url

        url = "ldap://ldap.example.com/cn=Barbara Jensen,dc=example,dc=com?cn,mail,telephoneNumber"
        expected = "ldap://ldap.example.com/cn=Barbara%20Jensen,dc=example,dc=com?cn,mail,telephoneNumber"
        expect(SS.follow_up_url_encode!(url)).to eq expected
      end
    end
  end
end
