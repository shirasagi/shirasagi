require 'spec_helper'

describe SS::Csv::CsvImporter do
  describe ".from_label" do
    context "with Cms::Page's state" do
      let(:item) { Cms::Page.new }

      it do
        expect(described_class.from_label(nil, item.state_options, item.state_private_options)).to be_nil
        expect(described_class.from_label("", item.state_options, item.state_private_options)).to be_nil
        expect(described_class.from_label("公開", item.state_options, item.state_private_options)).to eq "public"
        expect(described_class.from_label("非公開", item.state_options, item.state_private_options)).to eq "closed"
        expect(described_class.from_label("公開待ち", item.state_options, item.state_private_options)).to eq "ready"
      end
    end

    context "with Cms::Page's contact_state" do
      let(:item) { Cms::Page.new }

      it do
        expect(described_class.from_label(nil, item.contact_state_options)).to be_nil
        expect(described_class.from_label("", item.contact_state_options)).to be_nil
        expect(described_class.from_label("表示", item.contact_state_options)).to eq "show"
        expect(described_class.from_label("非表示", item.contact_state_options)).to eq "hide"
      end
    end

    context "with Article::Page's related_page_sort" do
      let(:item) { Article::Page.new }

      it do
        options = [ item.related_page_sort_options, item.related_page_sort_compat_options ]
        expect(described_class.from_label(nil, *options)).to be_nil
        expect(described_class.from_label("", *options)).to be_nil
        expect(described_class.from_label("タイトル", *options)).to eq "name"
        expect(described_class.from_label("ファイル名", *options)).to eq "filename"
        expect(described_class.from_label("作成日時", *options)).to eq "created"
        expect(described_class.from_label("更新日時", *options)).to eq "updated -1"
        expect(described_class.from_label("公開日時", *options)).to eq "released -1"
        expect(described_class.from_label("指定順（昇順）", *options)).to eq "order"
        expect(described_class.from_label("指定順（降順）", *options)).to eq "order -1"
        expect(described_class.from_label("イベント日", *options)).to eq "event_dates"
        expect(described_class.from_label("イベント日(未終了)", *options)).to eq "unfinished_event_dates"

        # for compatibilities
        expect(described_class.from_label("指定順", *options)).to eq "order"
      end
    end
  end

  describe ".to_array" do
    context "with default delimiter" do
      it do
        expect(described_class.to_array(nil)).to be_blank
        expect(described_class.to_array("")).to be_blank
        expect(described_class.to_array("a")).to eq %w(a)
        expect(described_class.to_array("a\nb")).to eq %w(a b)
        expect(described_class.to_array("a\n\nb")).to eq [ "a", "", "b" ]
      end
    end

    context "with comma as delimiter" do
      it do
        expect(described_class.to_array(nil, delim: ",")).to be_blank
        expect(described_class.to_array("", delim: ",")).to be_blank
        expect(described_class.to_array("a", delim: ",")).to eq %w(a)
        expect(described_class.to_array("a,b", delim: ",")).to eq %w(a b)
        expect(described_class.to_array("a,,b", delim: ",")).to eq [ "a", "", "b" ]
      end
    end
  end
end
