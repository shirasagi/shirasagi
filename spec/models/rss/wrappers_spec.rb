require 'spec_helper'

describe Rss::Wrappers, dbscope: :example do
  describe ".parse" do
    context "when rdf is given" do
      let(:file) { Rails.root.join("spec", "fixtures", "rss", "sample-rdf.xml") }
      subject do
        rss = described_class.parse(file)
        items = []
        rss.each do |item|
          items << { name: item.name, link: item.link, html: item.html, released: item.released }
        end
        items
      end

      it do
        expect(subject.length).to eq 5
        expect(subject[0][:name]).to eq '記事1'
        expect(subject[0][:link]).to eq 'http://example.jp/rdf/1.html'
        expect(subject[0][:html]).to eq '本文1'
        expect(subject[0][:released]).to eq Time.zone.parse('2015-06-12T19:00:00+09:00')
      end
    end

    context "when rss is given" do
      let(:file) { Rails.root.join("spec", "fixtures", "rss", "sample-rss.xml") }
      subject do
        rss = described_class.parse(file)
        items = []
        rss.each do |item|
          items << { name: item.name, link: item.link, html: item.html, released: item.released }
        end
        items
      end

      it do
        expect(subject.length).to eq 5
        expect(subject[0][:name]).to eq '記事1'
        expect(subject[0][:link]).to eq 'http://example.jp/rss/1.html'
        expect(subject[0][:html]).to eq '本文1'
        expect(subject[0][:released]).to eq Time.zone.parse('2015-06-12T19:00:00+09:00')
      end
    end

    context "when atom is given" do
      let(:file) { Rails.root.join("spec", "fixtures", "rss", "sample-atom.xml") }
      subject do
        rss = described_class.parse(file)
        items = []
        rss.each do |item|
          items << { name: item.name, link: item.link, html: item.html, released: item.released }
        end
        items
      end

      it do
        expect(subject.length).to eq 5
      end

      it do
        expect(subject[0][:name]).to eq '記事1'
        expect(subject[0][:link]).to eq 'http://example.jp/atom/1.html'
        expect(subject[0][:html]).to eq '本文1'
        expect(subject[0][:released]).to eq Time.zone.parse('2015-06-12T19:00:00+09:00')
      end

      it do
        # second item's summary is xhtml
        expect(subject[1][:name]).to eq '記事2'
        expect(subject[1][:link]).to eq 'http://example.jp/atom/2.html'
        expect(subject[1][:html]).to eq '<div xmlns="http://www.w3.org/1999/xhtml">本文2</div>'
        expect(subject[1][:released]).to eq Time.zone.parse('2015-06-11T14:00:00+09:00')
      end

      it do
        # third item's title is xhtml
        expect(subject[2][:name]).to eq '記事3'
        expect(subject[2][:link]).to eq 'http://example.jp/atom/3.html'
        expect(subject[2][:html]).to eq '本文3'
        expect(subject[2][:released]).to eq Time.zone.parse('2015-06-10T09:00:00+09:00')
      end
    end
  end
end
