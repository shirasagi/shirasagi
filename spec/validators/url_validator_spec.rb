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

    context 'with valid url' do
      subject! { clazz.new("http://#{unique_id}.example.jp/") }

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

    context 'with invalid scheme' do
      subject! { clazz.new("http://#{unique_id}.example.jp/") }

      it do
        expect(subject).to be_invalid
        expect(subject.errors[:url]).to have(1).items
        expect(subject.errors[:url]).to include("only https is allowed")
      end
    end
  end
end
