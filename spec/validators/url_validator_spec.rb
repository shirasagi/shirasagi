require 'spec_helper'

describe UrlValidator, type: :validator do
  let!(:clazz) do
    Struct.new(:url) do
      include ActiveModel::Validations

      def self.model_name
        ActiveModel::Name.new(self, nil, "temp")
      end
    end
  end

  # ブラウザでは外部ホストと解釈される値や、属性・ヘッダーインジェクションの恐れがある値。
  # どのオプションでも invalid でなければならない。
  let(:malicious_urls) do
    [
      "///evil.example",
      "////evil.example",
      "/\\evil.example",
      "/\\/evil.example",
      "/%5Cevil.example",
      "/\t/evil.example",
      "/\n/evil.example",
      "/%09/evil.example",
      "https:/evil.example",
      "https:evil.example",
      "https:///evil.example",
      "https://evil.example\\@example.jp/",
      "https://example.jp@evil.example/",
      "https://example.jp\\evil.example/",
      "https://example.jp/\r\nSet-Cookie:a=b",
      "/docs/\r\nSet-Cookie:a=b",
      "/docs/\u0000.html",
      "/docs/..\\..\\README.html",
      %(https://example.jp/" onclick="console.log('xss')" data-dummy="),
      %(/docs/?q="><script>console.log('xss')</script>),
      %(/docs/#"><script>console.log('xss')</script>),
      "/docs/<script>console.log('xss')</script>",
    ]
  end

  shared_examples "what url validator is" do
    it do
      test_cases.each do |test_case|
        item = clazz.new(test_case[:url])
        if test_case[:result] == :valid
          expect(item).to be_valid, "expected #{test_case[:url].inspect} to be valid"
        else
          expect(item).to be_invalid, "expected #{test_case[:url].inspect} to be invalid"
          expect(item.errors[:url]).to have(1).items
          expect(item.errors[:url]).to include(test_case[:message] || I18n.t("errors.messages.url"))
        end
      end
    end
  end

  context "without any options" do
    let(:test_cases) do
      [
        { url: nil, result: :valid },
        { url: "", result: :valid },
        { url: "http://#{unique_id}.example.jp/", result: :valid },
        { url: "https://#{unique_id}.example.jp/", result: :valid },
        { url: "HTTP://#{unique_id}.example.jp/", result: :valid },
        { url: "HTTPS://#{unique_id}.example.jp/", result: :valid },
        { url: "javascript:alert('hello');", result: :invalid },
        { url: "{{{}}}", result: :invalid },
        { url: "//www.example.jp/docs/3481.html", result: :invalid },
        { url: "//www.example.jp", result: :invalid },
        { url: "//www.example.jp/", result: :invalid },
        { url: "//www.example.jp/docs/../../README.html", result: :invalid },
        { url: "/docs/3481.html", result: :invalid },
        { url: "docs/3481.html", result: :invalid },
        { url: "/#{unique_id}", result: :invalid },
        { url: "/#{unique_id}/", result: :invalid },
        { url: unique_id, result: :invalid },
        { url: "/docs/../../README.html", result: :invalid },
        { url: "docs/../../README.html", result: :invalid },
        { url: "/docs/%2E%2E/%2E%2E/README.html", result: :invalid },
        { url: "docs/%2E%2E/%2E%2E/README.html", result: :invalid },
        { url: "/日本語", result: :invalid },
        { url: "日本語", result: :invalid },
        { url: %(#" onclick="console.log('xss')" data-dummy="), result: :invalid },
        { url: %(/" onclick="console.log('xss')" data-dummy="), result: :invalid },
        { url: "\\evil.example", result: :invalid },
        { url: "\\\\evil.example", result: :invalid },
      ] + malicious_urls.map { { url: _1, result: :invalid } }
    end

    before do
      clazz.validates :url, url: true
    end

    it_behaves_like "what url validator is"
  end

  context "with scheme and message options" do
    let(:message) { "only https is allowed" }
    let(:test_cases) do
      [
        { url: nil, result: :valid },
        { url: "", result: :valid },
        { url: "http://#{unique_id}.example.jp/", result: :invalid, message: message },
        { url: "https://#{unique_id}.example.jp/", result: :valid },
        { url: "HTTP://#{unique_id}.example.jp/", result: :invalid, message: message },
        { url: "HTTPS://#{unique_id}.example.jp/", result: :valid },
        { url: "javascript:alert('hello');", result: :invalid, message: message },
        { url: "{{{}}}", result: :invalid, message: message },
        { url: "//www.example.jp/docs/3481.html", result: :invalid, message: message },
        { url: "//www.example.jp", result: :invalid, message: message },
        { url: "//www.example.jp/", result: :invalid, message: message },
        { url: "//www.example.jp/docs/../../README.html", result: :invalid, message: message },
        { url: "/docs/3481.html", result: :invalid, message: message },
        { url: "docs/3481.html", result: :invalid, message: message },
        { url: "/#{unique_id}", result: :invalid, message: message },
        { url: "/#{unique_id}/", result: :invalid, message: message },
        { url: unique_id, result: :invalid, message: message },
        { url: "/docs/../../README.html", result: :invalid, message: message },
        { url: "docs/../../README.html", result: :invalid, message: message },
        { url: "/docs/%2E%2E/%2E%2E/README.html", result: :invalid, message: message },
        { url: "docs/%2E%2E/%2E%2E/README.html", result: :invalid, message: message },
        { url: "/日本語", result: :invalid, message: message },
        { url: "日本語", result: :invalid, message: message },
        { url: %(#" onclick="console.log('xss')" data-dummy="), result: :invalid, message: message },
        { url: %(/" onclick="console.log('xss')" data-dummy="), result: :invalid, message: message },
        { url: "\\evil.example", result: :invalid, message: message },
        { url: "\\\\evil.example", result: :invalid, message: message },
      ] + malicious_urls.map { { url: _1, result: :invalid, message: message } }
    end

    before do
      clazz.validates :url, url: { scheme: "https", message: message }
    end

    it_behaves_like "what url validator is"
  end

  context "with absolute_path option" do
    let(:test_cases) do
      [
        { url: nil, result: :valid },
        { url: "", result: :valid },
        { url: "http://#{unique_id}.example.jp/", result: :valid },
        { url: "https://#{unique_id}.example.jp/", result: :valid },
        { url: "HTTP://#{unique_id}.example.jp/", result: :valid },
        { url: "HTTPS://#{unique_id}.example.jp/", result: :valid },
        { url: "javascript:alert('hello');", result: :invalid },
        { url: "{{{}}}", result: :invalid },
        { url: "//www.example.jp/docs/3481.html", result: :valid },
        { url: "//www.example.jp", result: :valid },
        { url: "//www.example.jp/", result: :valid },
        { url: "//www.example.jp/docs/../../README.html", result: :invalid },
        { url: "/docs/3481.html", result: :valid },
        { url: "docs/3481.html", result: :invalid },
        { url: "/#{unique_id}", result: :valid },
        { url: "/#{unique_id}/", result: :valid },
        { url: unique_id, result: :invalid },
        { url: "/docs/../../README.html", result: :invalid },
        { url: "docs/../../README.html", result: :invalid },
        { url: "/docs/%2E%2E/%2E%2E/README.html", result: :invalid },
        { url: "docs/%2E%2E/%2E%2E/README.html", result: :invalid },
        { url: "/日本語", result: :valid },
        { url: "日本語", result: :invalid },
        { url: %(#" onclick="console.log('xss')" data-dummy="), result: :invalid },
        { url: %(/" onclick="console.log('xss')" data-dummy="), result: :invalid },
        { url: "\\evil.example", result: :invalid },
        { url: "\\\\evil.example", result: :invalid },
      ] + malicious_urls.map { { url: _1, result: :invalid } }
    end

    before do
      clazz.validates :url, url: { absolute_path: true }
    end

    it_behaves_like "what url validator is"
  end

  context "with relative_path option" do
    let(:test_cases) do
      [
        { url: nil, result: :valid },
        { url: "", result: :valid },
        { url: "http://#{unique_id}.example.jp/", result: :valid },
        { url: "https://#{unique_id}.example.jp/", result: :valid },
        { url: "HTTP://#{unique_id}.example.jp/", result: :valid },
        { url: "HTTPS://#{unique_id}.example.jp/", result: :valid },
        { url: "javascript:alert('hello');", result: :invalid },
        # 以下は invalid にしたいが valid になるのが課題。
        # relative_path: true の使用は控えること。
        { url: "{{{}}}", result: :valid },
        { url: "//www.example.jp/docs/3481.html", result: :valid },
        { url: "//www.example.jp", result: :valid },
        { url: "//www.example.jp/", result: :valid },
        { url: "//www.example.jp/docs/../../README.html", result: :invalid },
        { url: "/docs/3481.html", result: :valid },
        { url: "docs/3481.html", result: :valid },
        { url: "/#{unique_id}", result: :valid },
        { url: "/#{unique_id}/", result: :valid },
        { url: unique_id, result: :valid },
        { url: "/docs/../../README.html", result: :invalid },
        { url: "docs/../../README.html", result: :invalid },
        { url: "/docs/%2E%2E/%2E%2E/README.html", result: :invalid },
        { url: "docs/%2E%2E/%2E%2E/README.html", result: :invalid },
        { url: "/日本語", result: :valid },
        { url: "日本語", result: :valid },
        { url: %(#" onclick="console.log('xss')" data-dummy="), result: :invalid },
        { url: %(/" onclick="console.log('xss')" data-dummy="), result: :invalid },
        { url: "\\evil.example", result: :invalid },
        { url: "\\\\evil.example", result: :invalid },
      ] + malicious_urls.map { { url: _1, result: :invalid } }
    end

    before do
      clazz.validates :url, url: { absolute_path: true, relative_path: true }
    end

    it_behaves_like "what url validator is"
  end

  context "with only_path option" do
    let(:test_cases) do
      [
        { url: nil, result: :valid },
        { url: "", result: :valid },
        { url: "http://#{unique_id}.example.jp/", result: :invalid },
        { url: "https://#{unique_id}.example.jp/", result: :invalid },
        { url: "HTTP://#{unique_id}.example.jp/", result: :invalid },
        { url: "HTTPS://#{unique_id}.example.jp/", result: :invalid },
        { url: "javascript:alert('hello');", result: :invalid },
        { url: "{{{}}}", result: :invalid },
        { url: "//www.example.jp/docs/3481.html", result: :invalid },
        { url: "//www.example.jp", result: :invalid },
        { url: "//www.example.jp/", result: :invalid },
        { url: "//www.example.jp/docs/../../README.html", result: :invalid },
        { url: "/docs/3481.html", result: :valid },
        { url: "docs/3481.html", result: :invalid },
        { url: "/#{unique_id}", result: :valid },
        { url: "/#{unique_id}/", result: :valid },
        { url: unique_id, result: :invalid },
        { url: "/docs/../../README.html", result: :invalid },
        { url: "docs/../../README.html", result: :invalid },
        { url: "/docs/%2E%2E/%2E%2E/README.html", result: :invalid },
        { url: "docs/%2E%2E/%2E%2E/README.html", result: :invalid },
        { url: "/日本語", result: :valid },
        { url: "日本語", result: :invalid },
        { url: %(#" onclick="console.log('xss')" data-dummy="), result: :invalid },
        { url: %(/" onclick="console.log('xss')" data-dummy="), result: :invalid },
        { url: "\\evil.example", result: :invalid },
        { url: "\\\\evil.example", result: :invalid },
      ] + malicious_urls.map { { url: _1, result: :invalid } }
    end

    before do
      clazz.validates :url, url: { absolute_path: true, only_path: true }
    end

    it_behaves_like "what url validator is"
  end

  context "with ldap scheme" do
    let(:test_cases) do
      [
        { url: "ldap://localhost:389/", result: :valid },
        { url: "ldaps://ldap.example.jp/", result: :valid },
        { url: "LDAP://ldap.example.jp/", result: :valid },
        { url: "https://ldap.example.jp/", result: :invalid },
        { url: "ldap://user@ldap.example.jp/", result: :invalid },
      ]
    end

    before do
      clazz.validates :url, url: { scheme: %w(ldap ldaps) }
    end

    it_behaves_like "what url validator is"
  end

  context "with legitimate urls" do
    let(:test_cases) do
      [
        { url: "https://#{unique_id}.example.jp:8443/docs/3481.html?q=a%22b&r=%3Cc%3E#top", result: :valid },
        { url: "https://#{unique_id}.example.jp/docs/it's.html", result: :valid },
        { url: "//#{unique_id}.example.jp//docs/3481.html", result: :valid },
        { url: "/docs/%E6%97%A5%E6%9C%AC%E8%AA%9E.html", result: :valid },
        { url: "/docs/3481.html?q=%22%3Cscript%3E", result: :valid },
        { url: "/docs/3481.html#top", result: :valid },
      ]
    end

    before do
      clazz.validates :url, url: { absolute_path: true }
    end

    it_behaves_like "what url validator is"
  end

  # DB には SS.follow_up_url_encode! でエンコードした値が保存されるので、エンコード後の値でも外部ホストと解釈されないこと
  context "with urls encoded by SS.follow_up_url_encode!" do
    let(:test_cases) do
      [
        "///evil.example",
        "////evil.example",
        "/\\evil.example",
        "/\t/evil.example",
        "https:/evil.example",
        "https:evil.example",
        "https:///evil.example",
        "https://evil.example\\@example.jp/",
        "https://example.jp@evil.example/",
        "https://example.jp/\r\nSet-Cookie:a=b",
      ].map { { url: SS.follow_up_url_encode!(_1), result: :invalid } }
    end

    before do
      clazz.validates :url, url: { absolute_path: true, relative_path: true }
    end

    it_behaves_like "what url validator is"
  end
end
