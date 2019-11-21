require 'spec_helper'

describe Rss::Wrappers, dbscope: :example do
  describe ".parse" do
    before { WebMock.reset! }
    after { WebMock.reset! }

    context "when rdf file is given" do
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

      shared_examples "rss" do
        it do
          expect(subject.length).to eq 5
          expect(subject[0][:name]).to eq '記事1'
          expect(subject[0][:link]).to eq 'http://example.jp/rss/1.html'
          expect(subject[0][:html]).to eq '本文1'
          expect(subject[0][:released]).to eq Time.zone.parse('2015-06-12T19:00:00+09:00')
        end
      end

      context "file path is given" do
        subject do
          rss = described_class.parse(file)
          items = []
          rss.each do |item|
            items << { name: item.name, link: item.link, html: item.html, released: item.released }
          end
          items
        end

        it_behaves_like "rss"
      end

      context "file is given" do
        subject do
          rss = ::File.open(file) { |f| described_class.parse(f) }
          items = []
          rss.each do |item|
            items << { name: item.name, link: item.link, html: item.html, released: item.released }
          end
          items
        end

        it_behaves_like "rss"
      end

      context "url is given" do
        let(:url) { "http://#{unique_id}.example.jp/rss.xml" }

        before do
          stub_request(:get, url).to_return(status: 200, body: ::File.read(file), headers: {})
        end

        subject do
          rss = described_class.parse(url)
          items = []
          rss.each do |item|
            items << { name: item.name, link: item.link, html: item.html, released: item.released }
          end
          items
        end

        it_behaves_like "rss"
      end
    end

    context "when atom file is given" do
      let(:file) { Rails.root.join("spec", "fixtures", "rss", "sample-atom.xml") }

      shared_examples "atom" do
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

      context "file path is given" do
        subject do
          rss = described_class.parse(file)
          items = []
          rss.each do |item|
            items << { name: item.name, link: item.link, html: item.html, released: item.released }
          end
          items
        end

        it_behaves_like "atom"
      end

      context "file is given" do
        subject do
          rss = ::File.open(file) { |f| described_class.parse(f) }
          items = []
          rss.each do |item|
            items << { name: item.name, link: item.link, html: item.html, released: item.released }
          end
          items
        end

        it_behaves_like "atom"
      end

      context "url is given" do
        let(:url) { "http://#{unique_id}.example.jp/rss.xml" }

        before do
          stub_request(:get, url).to_return(status: 200, body: ::File.read(file), headers: {})
        end

        subject do
          rss = described_class.parse(url)
          items = []
          rss.each do |item|
            items << { name: item.name, link: item.link, html: item.html, released: item.released }
          end
          items
        end

        it_behaves_like "atom"
      end
    end
  end
end
