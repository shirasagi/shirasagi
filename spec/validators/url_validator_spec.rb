require 'spec_helper'

describe UrlValidator, type: :validator do
  context "without any options" do
    let!(:clazz) do
      Struct.new(:url) do
        include ActiveModel::Validations

        def self.model_name
          ActiveModel::Name.new(self, nil, "temp")
        end
        validates :url, url: true
      end
    end

    context 'with valid url #1' do
      subject! { clazz.new("http://#{unique_id}.example.jp/") }

      it do
        expect(subject).to be_valid
      end
    end

    context 'with valid url #2' do
      subject! { clazz.new("HTTPS://#{unique_id}.example.jp/") }

      it do
        expect(subject).to be_valid
      end
    end

    context 'with invalid scheme' do
      subject { clazz.new("javascript:alert('hello');") }

      it do
        expect(subject).to be_invalid
        expect(subject.errors[:url]).to have(1).items
        expect(subject.errors[:url]).to include(I18n.t("errors.messages.url"))
      end
    end

    context 'with invalid url' do
      subject { clazz.new("{{{}}}") }

      it do
        expect(subject).to be_invalid
        expect(subject.errors[:url]).to have(1).items
        expect(subject.errors[:url]).to include(I18n.t("errors.messages.url"))
      end
    end
  end

  context "with scheme and message options" do
    let!(:clazz) do
      Struct.new(:url) do
        include ActiveModel::Validations

        def self.model_name
          ActiveModel::Name.new(self, nil, "temp")
        end
        validates :url, url: { scheme: "https", message: "only https is allowed" }
      end
    end

    context 'with valid url' do
      subject! { clazz.new("https://#{unique_id}.example.jp/") }

      it do
        expect(subject).to be_valid
      end
    end

    context 'with valid url' do
      subject! { clazz.new("HTTPS://#{unique_id}.example.jp/") }

      it do
        expect(subject).to be_valid
      end
    end

    context 'with invalid scheme' do
      subject! { clazz.new("http://#{unique_id}.example.jp/") }

      it do
        expect(subject).to be_invalid
        expect(subject.errors[:url]).to have(1).items
        expect(subject.errors[:url]).to include("only https is allowed")
      end
    end
  end

  context "with absolute_path option" do
    let!(:clazz) do
      Struct.new(:url) do
        include ActiveModel::Validations

        def self.model_name
          ActiveModel::Name.new(self, nil, "temp")
        end
        validates :url, url: { absolute_path: true }
      end
    end

    context 'with valid absolute url #1' do
      subject! { clazz.new("//www.example.jp/docs/3481.html") }

      it do
        expect(subject).to be_valid
      end
    end

    context 'with valid absolute url #2' do
      subject! { clazz.new("//www.example.jp") }

      it do
        expect(subject).to be_valid
      end
    end

    context 'with valid absolute url #3' do
      subject! { clazz.new("//www.example.jp/") }

      it do
        expect(subject).to be_valid
      end
    end

    context 'with valid absolute url containing relative path' do
      subject! { clazz.new("//www.example.jp/docs/../../README.html") }

      it do
        expect(subject).to be_invalid
        expect(subject.errors[:url]).to have(1).items
        expect(subject.errors[:url]).to include(I18n.t("errors.messages.url"))
      end
    end

    context 'with valid absolute path #1' do
      subject! { clazz.new("/docs/3481.html") }

      it do
        expect(subject).to be_valid
      end
    end

    context 'with valid absolute path #2' do
      subject! { clazz.new("/#{unique_id}/") }

      it do
        expect(subject).to be_valid
      end
    end

    context 'with valid absolute path containing relative path' do
      subject! { clazz.new("/docs/../../README.html") }

      it do
        expect(subject).to be_invalid
        expect(subject.errors[:url]).to have(1).items
        expect(subject.errors[:url]).to include(I18n.t("errors.messages.url"))
      end
    end

    context 'with valid Japanese path' do
      subject! { clazz.new("/日本語") }

      it do
        expect(subject).to be_valid
      end
    end

    context 'with valid relative path #1' do
      subject! { clazz.new("docs/3481.html") }

      it do
        expect(subject).to be_invalid
        expect(subject.errors[:url]).to have(1).items
        expect(subject.errors[:url]).to include(I18n.t("errors.messages.url"))
      end
    end

    context 'with valid relative path #2' do
      subject! { clazz.new(unique_id) }

      it do
        expect(subject).to be_invalid
        expect(subject.errors[:url]).to have(1).items
        expect(subject.errors[:url]).to include(I18n.t("errors.messages.url"))
      end
    end

    context 'with valid relative path containing relative path #1' do
      subject! { clazz.new("docs/../../README.html") }

      it do
        expect(subject).to be_invalid
        expect(subject.errors[:url]).to have(1).items
        expect(subject.errors[:url]).to include(I18n.t("errors.messages.url"))
      end
    end

    context 'with valid relative path containing relative path #2' do
      subject! { clazz.new("docs/%2E%2E/%2E%2E/README.html") }

      it do
        expect(subject).to be_invalid
        expect(subject.errors[:url]).to have(1).items
        expect(subject.errors[:url]).to include(I18n.t("errors.messages.url"))
      end
    end

    context 'with invalid url' do
      subject! { clazz.new("{{{}}}") }

      it do
        expect(subject).to be_invalid
        expect(subject.errors[:url]).to have(1).items
        expect(subject.errors[:url]).to include(I18n.t("errors.messages.url"))
      end
    end

    context 'with xss case1' do
      subject! { clazz.new(%(#" onclick="console.log('xss')" data-dummy=")) }

      it do
        expect(subject).to be_invalid
        expect(subject.errors[:url]).to have(1).items
        expect(subject.errors[:url]).to include(I18n.t("errors.messages.url"))
      end
    end

    # 次のケースは invalid となって欲しいところだが valid となる
    # SS.follow_up_url_encode! で URL エンコードした値をDBに保存すること
    context 'with xss case2' do
      subject! { clazz.new(%(/" onclick="console.log('xss')" data-dummy=")) }

      it do
        expect(subject).to be_valid
      end
    end

    context 'with invalid authority #1' do
      subject! { clazz.new("\\evil.example") }

      it do
        expect(subject).to be_invalid
        expect(subject.errors[:url]).to have(1).items
        expect(subject.errors[:url]).to include(I18n.t("errors.messages.url"))
      end
    end

    context 'with invalid authority #2' do
      subject! { clazz.new("\\\\evil.example") }

      it do
        expect(subject).to be_invalid
        expect(subject.errors[:url]).to have(1).items
        expect(subject.errors[:url]).to include(I18n.t("errors.messages.url"))
      end
    end
  end

  context "with relative_path option" do
    let!(:clazz) do
      Struct.new(:url) do
        include ActiveModel::Validations

        def self.model_name
          ActiveModel::Name.new(self, nil, "temp")
        end
        validates :url, url: { absolute_path: true, relative_path: true }
      end
    end

    context 'with valid absolute url #1' do
      subject! { clazz.new("//www.example.jp/docs/3481.html") }

      it do
        expect(subject).to be_valid
      end
    end

    context 'with valid absolute url #2' do
      subject! { clazz.new("//www.example.jp") }

      it do
        expect(subject).to be_valid
      end
    end

    context 'with valid absolute url #3' do
      subject! { clazz.new("//www.example.jp/") }

      it do
        expect(subject).to be_valid
      end
    end

    context 'with valid absolute url containing relative path' do
      subject! { clazz.new("//www.example.jp/docs/../../README.html") }

      it do
        expect(subject).to be_invalid
        expect(subject.errors[:url]).to have(1).items
        expect(subject.errors[:url]).to include(I18n.t("errors.messages.url"))
      end
    end

    context 'with valid absolute path #1' do
      subject! { clazz.new("/docs/3481.html") }

      it do
        expect(subject).to be_valid
      end
    end

    context 'with valid absolute path #2' do
      subject! { clazz.new("/#{unique_id}/") }

      it do
        expect(subject).to be_valid
      end
    end

    context 'with valid absolute path containing relative path' do
      subject! { clazz.new("/docs/../../README.html") }

      it do
        expect(subject).to be_invalid
        expect(subject.errors[:url]).to have(1).items
        expect(subject.errors[:url]).to include(I18n.t("errors.messages.url"))
      end
    end

    context 'with valid Japanese path' do
      subject! { clazz.new("/日本語") }

      it do
        expect(subject).to be_valid
      end
    end

    context 'with valid relative path #1' do
      subject! { clazz.new("docs/3481.html") }

      it do
        expect(subject).to be_valid
      end
    end

    context 'with valid relative path #2' do
      subject! { clazz.new(unique_id) }

      it do
        expect(subject).to be_valid
      end
    end

    context 'with valid relative path containing relative path #1' do
      subject! { clazz.new("docs/../../README.html") }

      it do
        expect(subject).to be_invalid
        expect(subject.errors[:url]).to have(1).items
        expect(subject.errors[:url]).to include(I18n.t("errors.messages.url"))
      end
    end

    context 'with valid relative path containing relative path #2' do
      subject! { clazz.new("docs/%2E%2E/%2E%2E/README.html") }

      it do
        expect(subject).to be_invalid
        expect(subject.errors[:url]).to have(1).items
        expect(subject.errors[:url]).to include(I18n.t("errors.messages.url"))
      end
    end

    # 次のケースは invalid となって欲しいところだが valid となる
    # SS.follow_up_url_encode! で URL エンコードした値をDBに保存すること
    context 'with invalid url' do
      subject! { clazz.new("{{{}}}") }

      it do
        expect(subject).to be_valid
      end
    end

    context 'with xss case1' do
      subject! { clazz.new(%(#" onclick="console.log('xss')" data-dummy=")) }

      it do
        expect(subject).to be_invalid
        expect(subject.errors[:url]).to have(1).items
        expect(subject.errors[:url]).to include(I18n.t("errors.messages.url"))
      end
    end

    # 次のケースは invalid となって欲しいところだが valid となる
    # SS.follow_up_url_encode! で URL エンコードした値をDBに保存すること
    context 'with xss case2' do
      subject! { clazz.new(%(/" onclick="console.log('xss')" data-dummy=")) }

      it do
        expect(subject).to be_valid
      end
    end

    context 'with invalid authority #1' do
      subject! { clazz.new("\\evil.example") }

      it do
        expect(subject).to be_invalid
        expect(subject.errors[:url]).to have(1).items
        expect(subject.errors[:url]).to include(I18n.t("errors.messages.url"))
      end
    end

    context 'with invalid authority #2' do
      subject! { clazz.new("\\\\evil.example") }

      it do
        expect(subject).to be_invalid
        expect(subject.errors[:url]).to have(1).items
        expect(subject.errors[:url]).to include(I18n.t("errors.messages.url"))
      end
    end
  end
end
