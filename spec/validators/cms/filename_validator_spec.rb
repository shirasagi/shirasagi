require 'spec_helper'

describe Cms::FilenameValidator, type: :validator do
  context "with string field" do
    let!(:clazz) do
      Class.new do
        include ActiveModel::API
        include ActiveModel::Attributes

        attribute :filename, :string

        def self.model_name
          ActiveModel::Name.new(self, nil, "temp")
        end
      end
    end

    context "without any options" do
      before do
        clazz.validates :filename, "cms/filename" => true
      end

      context 'when valid filename is given #1' do
        subject! { clazz.new(filename: "a") }

        it do
          expect(subject).to be_valid
        end
      end

      context 'when valid filename is given #2' do
        subject! { clazz.new(filename: "A") }

        it do
          expect(subject).to be_valid
        end
      end

      context 'when valid filename is given #3' do
        subject! { clazz.new(filename: "a/b/c") }

        it do
          expect(subject).to be_valid
        end
      end

      context 'when valid filename is given #4' do
        subject! { clazz.new(filename: "A/B/C") }

        it do
          expect(subject).to be_valid
        end
      end

      context 'when filename with site modifier is given' do
        subject! { clazz.new(filename: "site:a/b/c") }

        it do
          expect(subject).to be_invalid
          expect(subject.errors[:filename]).to have(1).items
          expect(subject.errors[:filename]).to include(I18n.t("errors.messages.invalid"))
        end
      end

      context 'when filename with suffix is given' do
        subject! { clazz.new(filename: "a/b/c.html") }

        it do
          expect(subject).to be_invalid
          expect(subject.errors[:filename]).to have(1).items
          expect(subject.errors[:filename]).to include(I18n.t("errors.messages.invalid"))
        end
      end

      context 'when filename start with number is given' do
        subject! { clazz.new(filename: "1a") }

        it do
          expect(subject).to be_valid
        end
      end

      context 'when filename start with underscore is given' do
        subject! { clazz.new(filename: "_a") }

        it do
          expect(subject).to be_valid
        end
      end

      context 'when filename start with hyphen is given' do
        subject! { clazz.new(filename: "-a") }

        it do
          expect(subject).to be_valid
        end
      end

      context 'when filename start with dot is given' do
        subject! { clazz.new(filename: ".a") }

        it do
          expect(subject).to be_invalid
          expect(subject.errors[:filename]).to have(1).items
          expect(subject.errors[:filename]).to include(I18n.t("errors.messages.invalid"))
        end
      end

      context 'when valid filenames is given #1' do
        subject! { clazz.new(filename: %w(a a/b/c)) }

        it do
          expect(subject).to be_invalid
          expect(subject.errors[:filename]).to have(1).items
          expect(subject.errors[:filename]).to include(I18n.t("errors.messages.invalid"))
        end
      end

      context 'when none string is given to filename #1' do
        subject! { clazz.new(filename: 1) }

        it do
          expect(subject).to be_valid
        end
      end

      context 'when none string is given to filename #1' do
        subject! { clazz.new(filename: { a: 1 }) }

        it do
          expect(subject).to be_invalid
          expect(subject.errors[:filename]).to have(1).items
          expect(subject.errors[:filename]).to include(I18n.t("errors.messages.invalid"))
        end
      end
    end

    context "with 'site_modifier: true' option" do
      before do
        clazz.validates :filename, "cms/filename" => { site_modifier: true }
      end

      context 'when valid filename is given' do
        subject! { clazz.new(filename: "a/b/c") }

        it do
          expect(subject).to be_valid
        end
      end

      context 'when filename with site modifier is given' do
        subject! { clazz.new(filename: "site:a/b/c") }

        it do
          expect(subject).to be_valid
        end
      end
    end

    context "with 'site_modifier: true' option" do
      before do
        clazz.validates :filename, "cms/filename" => { site_modifier: true }
      end

      context 'when valid filename is given #1' do
        subject! { clazz.new(filename: "a/b/c") }

        it do
          expect(subject).to be_valid
        end
      end

      context 'when valid filename is given #1' do
        subject! { clazz.new(filename: "A/B/C") }

        it do
          expect(subject).to be_valid
        end
      end

      context 'when filename with site modifier is given #1' do
        subject! { clazz.new(filename: "site:a/b/c") }

        it do
          expect(subject).to be_valid
        end
      end

      context 'when filename with site modifier is given #2' do
        subject! { clazz.new(filename: "SITE:A/B/C") }

        it do
          expect(subject).to be_valid
        end
      end
    end

    context "with 'allow_suffixes:' option" do
      before do
        clazz.validates :filename, "cms/filename" => { allow_suffixes: ".html" }
      end

      context 'when valid filename is given #1' do
        subject! { clazz.new(filename: "a/b/c") }

        it do
          expect(subject).to be_valid
        end
      end

      context 'when valid filename is given #2' do
        subject! { clazz.new(filename: "A/B/C") }

        it do
          expect(subject).to be_valid
        end
      end

      context 'when filename with allowed suffix is given #1' do
        subject! { clazz.new(filename: "a/b/c.html") }

        it do
          expect(subject).to be_valid
        end
      end

      context 'when filename with allowed suffix is given #2' do
        subject! { clazz.new(filename: "A/B/C.html") }

        it do
          expect(subject).to be_valid
        end
      end

      context 'when filename with allowed suffix but upcase is given #1' do
        subject! { clazz.new(filename: "a/b/c.HTML") }

        it do
          expect(subject).to be_invalid
          expect(subject.errors[:filename]).to have(1).items
          expect(subject.errors[:filename]).to include(I18n.t("errors.messages.invalid"))
        end
      end

      context 'when filename with allowed suffix but upcase is given #2' do
        subject! { clazz.new(filename: "A/B/C.HTML") }

        it do
          expect(subject).to be_invalid
          expect(subject.errors[:filename]).to have(1).items
          expect(subject.errors[:filename]).to include(I18n.t("errors.messages.invalid"))
        end
      end

      context 'when filename with not-allowed suffix is given #1' do
        subject! { clazz.new(filename: "a/b/c.part.html") }

        it do
          expect(subject).to be_invalid
          expect(subject.errors[:filename]).to have(1).items
          expect(subject.errors[:filename]).to include(I18n.t("errors.messages.invalid"))
        end
      end
    end
  end

  context "with array field" do
    let!(:clazz) do
      Class.new do
        include ActiveModel::API

        attr_reader :filenames
        validates :filenames, "cms/filename" => { site_modifier: true }

        def self.model_name
          ActiveModel::Name.new(self, nil, "temp")
        end

        def filenames=(value)
          @filenames = Array(value)
        end
      end
    end

    context 'when valid filename is given #1' do
      subject! { clazz.new(filenames: "a") }

      it do
        expect(subject).to be_valid
      end
    end

    context 'when valid filename is given #2' do
      subject! { clazz.new(filenames: "A") }

      it do
        expect(subject).to be_valid
      end
    end

    context 'when valid filename is given #3' do
      subject! { clazz.new(filenames: "a/b/c") }

      it do
        expect(subject).to be_valid
      end
    end

    context 'when valid filename is given #4' do
      subject! { clazz.new(filenames: "A/B/C") }

      it do
        expect(subject).to be_valid
      end
    end

    context 'when filename with site modifier is given' do
      subject! { clazz.new(filenames: "site:a/b/c") }

      it do
        expect(subject).to be_valid
      end
    end

    context 'when filename with suffix is given' do
      subject! { clazz.new(filenames: "a/b/c.html") }

      it do
        expect(subject).to be_invalid
        expect(subject.errors[:filenames]).to have(1).items
        expect(subject.errors[:filenames]).to include(I18n.t("errors.messages.invalid"))
      end
    end

    context 'when filename start with number is given' do
      subject! { clazz.new(filenames: "1a") }

      it do
        expect(subject).to be_valid
      end
    end

    context 'when filename start with underscore is given' do
      subject! { clazz.new(filenames: "_a") }

      it do
        expect(subject).to be_valid
      end
    end

    context 'when filename start with hyphen is given' do
      subject! { clazz.new(filenames: "-a") }

      it do
        expect(subject).to be_valid
      end
    end

    context 'when filename start with dot is given' do
      subject! { clazz.new(filenames: ".a") }

      it do
        expect(subject).to be_invalid
        expect(subject.errors[:filenames]).to have(1).items
        expect(subject.errors[:filenames]).to include(I18n.t("errors.messages.invalid"))
      end
    end

    context 'when valid filenames is given #1' do
      subject! { clazz.new(filenames: %w(a a/b/c)) }

      it do
        expect(subject).to be_valid
      end
    end

    context 'when none string is given to filename #1' do
      subject! { clazz.new(filenames: 1) }

      it do
        expect(subject).to be_valid
      end
    end

    context 'when none string is given to filename #1' do
      subject! { clazz.new(filenames: { a: 1 }) }

      it do
        expect(subject).to be_invalid
        expect(subject.errors[:filenames]).to have(1).items
        expect(subject.errors[:filenames]).to include(I18n.t("errors.messages.invalid"))
      end
    end
  end
end
