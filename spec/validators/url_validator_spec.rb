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

  shared_examples "what url validator is" do
    it do
      test_cases.each do |test_case|
        item = clazz.new(test_case[:url])
        if test_case[:result] == :valid
          expect(item).to be_valid
        else
          expect(item).to be_invalid
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
      ]
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
      ]
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
        # 以下は invalid にしたいが valid になるのが課題。
        # このような抜けがあるので DB には SS.follow_up_url_encode! にてエンコードした文字列を格納すること。
        { url: %(/" onclick="console.log('xss')" data-dummy="), result: :valid },
        { url: "\\evil.example", result: :invalid },
        { url: "\\\\evil.example", result: :invalid },
      ]
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
        # 以下は invalid にしたいが valid になるのが課題。
        # このような抜けがあるので DB には SS.follow_up_url_encode! にてエンコードした文字列を格納すること。
        { url: %(/" onclick="console.log('xss')" data-dummy="), result: :valid },
        { url: "\\evil.example", result: :invalid },
        { url: "\\\\evil.example", result: :invalid },
      ]
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
        # 以下は invalid にしたいが valid になるのが課題。
        # このような抜けがあるので DB には SS.follow_up_url_encode! にてエンコードした文字列を格納すること。
        { url: %(/" onclick="console.log('xss')" data-dummy="), result: :valid },
        { url: "\\evil.example", result: :invalid },
        { url: "\\\\evil.example", result: :invalid },
      ]
    end

    before do
      clazz.validates :url, url: { absolute_path: true, only_path: true }
    end

    it_behaves_like "what url validator is"
  end
end
