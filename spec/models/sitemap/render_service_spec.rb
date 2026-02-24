require 'spec_helper'

describe Sitemap::RenderService, type: :model, dbscope: :example do
  context "initial setting" do
    let!(:node) { create :sitemap_node_page }
    let!(:item) { create :sitemap_page, cur_node: node }
    subject! { Sitemap::RenderService.new(cur_site: cms_site, cur_node: node, page: item) }

    it { expect(subject.load_whole_contents.map(&:url)).to include(node.url) }
    # it { expect(item.load_sitemap_urls(name: true)).to include("#{node.url} ##{node.name}") }
  end

  context 'when sitemap_page_state is hide' do
    let!(:article_node) { create :article_node_page }
    let!(:cms_page) { create :cms_page, cur_node: article_node, basename: "index.html" }
    let!(:article_page) { create :article_page, cur_node: article_node }
    let!(:node) { create :sitemap_node_page }
    let!(:item) { create :sitemap_page, cur_node: node, sitemap_page_state: 'hide' }
    subject! { Sitemap::RenderService.new(cur_site: cms_site, cur_node: node, page: item) }

    it { expect(subject.load_whole_contents.map(&:url)).to include(article_node.url) }
    it { expect(subject.load_whole_contents.map(&:url)).not_to include(cms_page.url) }
    it { expect(subject.load_whole_contents.map(&:url)).not_to include(article_page.url) }
    # it { expect(item.load_sitemap_urls(name: true)).to include("#{article_node.url} ##{article_node.name}") }
    # it { expect(item.load_sitemap_urls(name: true)).not_to include("#{article_page.url} ##{article_page.name}") }
  end

  context 'when sitemap_page_state is show' do
    let!(:article_node) { create :article_node_page }
    let!(:cms_page) { create :cms_page, cur_node: article_node, basename: "index.html" }
    let!(:article_page) { create :article_page, cur_node: article_node }
    let!(:node) { create :sitemap_node_page }
    let!(:item) { create :sitemap_page, cur_node: node, sitemap_page_state: 'show' }
    subject! { Sitemap::RenderService.new(cur_site: cms_site, cur_node: node, page: item) }

    it { expect(subject.load_whole_contents.map(&:url)).to include(article_node.url) }
    # index.htmlは含まれない（なお、理由は不明）
    it { expect(subject.load_whole_contents.map(&:url)).not_to include(cms_page.url) }
    it { expect(subject.load_whole_contents.map(&:url)).to include(article_page.url) }
    # it { expect(item.load_sitemap_urls(name: true)).to include("#{article_node.url} ##{article_node.name}") }
    # it { expect(item.load_sitemap_urls(name: true)).to include("#{article_page.url} ##{article_page.name}") }
  end

  context "sitemap/addon/body#sitemap_deny_urls" do
    context 'tooltip #1: 前方一致したURLを除外します' do
      let!(:article_node) { create :article_node_page }
      let!(:article_page1) { create :article_page, cur_node: article_node }
      let!(:article_page2) { create :article_page, cur_node: article_node }
      let!(:node) { create :sitemap_node_page }
      let!(:item) do
        create :sitemap_page, cur_node: node, sitemap_page_state: 'show', sitemap_deny_urls: [ "/#{article_node.filename}/" ]
      end
      subject! { Sitemap::RenderService.new(cur_site: cms_site, cur_node: node, page: item) }

      it do
        subject.load_whole_contents.tap do |load_whole_contents|
          expect(load_whole_contents.map(&:url)).not_to include(article_node.url)
          expect(load_whole_contents.map(&:url)).not_to include(article_page1.url)
          expect(load_whole_contents.map(&:url)).not_to include(article_page2.url)
        end
      end
    end

    context 'tooltip #2: docs/archiveフォルダー以下すべてを除外' do
      let!(:article_node) { create :article_node_page }
      let!(:archive_node) { create :cms_node_archive, cur_node: article_node }
      let!(:cms_page1) { create :cms_page, cur_node: article_node, basename: "index.html" }
      let!(:article_page1) { create :article_page, cur_node: article_node }
      let!(:article_page2) { create :article_page, cur_node: article_node }
      let!(:node) { create :sitemap_node_page }
      let!(:item) do
        create :sitemap_page, cur_node: node, sitemap_page_state: 'show', sitemap_deny_urls: [ "/#{archive_node.filename}/" ]
      end
      subject! { Sitemap::RenderService.new(cur_site: cms_site, cur_node: node, page: item) }

      it do
        subject.load_whole_contents.tap do |load_whole_contents|
          expect(load_whole_contents.map(&:url)).not_to include(cms_page1.url)
          expect(load_whole_contents.map(&:url)).to include(article_page1.url)
          expect(load_whole_contents.map(&:url)).to include(article_page2.url)
          expect(load_whole_contents.map(&:url)).not_to include(archive_node.url)
        end
      end
    end

    context 'tooltip #3: ページのURLを指定して除外' do
      let!(:article_node) { create :article_node_page }
      let!(:article_page1) { create :article_page, cur_node: article_node }
      let!(:article_page2) { create :article_page, cur_node: article_node }
      let!(:node) { create :sitemap_node_page }
      let!(:item) do
        create :sitemap_page, cur_node: node, sitemap_page_state: 'show', sitemap_deny_urls: [ "#{article_page2.filename}" ]
      end
      subject! { Sitemap::RenderService.new(cur_site: cms_site, cur_node: node, page: item) }

      it do
        subject.load_whole_contents.tap do |load_whole_contents|
          expect(load_whole_contents.map(&:url)).to include(article_page1.url)
          expect(load_whole_contents.map(&:url)).not_to include(article_page2.url)
        end
      end
    end

    context 'tooltip #4: /news_2023/、/news_2022/を前方一致で一括して除外' do
      let(:prefix) { "news" }
      let!(:article_node2022) { create :article_node_page, basename: "#{prefix}_2022" }
      let!(:article_node2023) { create :article_node_page, basename: "#{prefix}_2023" }
      let!(:article_page2022_1) { create :article_page, cur_node: article_node2022 }
      let!(:article_page2022_2) { create :article_page, cur_node: article_node2022 }
      let!(:article_page2023_1) { create :article_page, cur_node: article_node2023 }
      let!(:article_page2023_2) { create :article_page, cur_node: article_node2023 }
      let!(:node) { create :sitemap_node_page }
      let!(:item) do
        create :sitemap_page, cur_node: node, sitemap_page_state: 'show', sitemap_deny_urls: [ "#{prefix}_" ]
      end
      subject! { Sitemap::RenderService.new(cur_site: cms_site, cur_node: node, page: item) }

      it do
        subject.load_whole_contents.tap do |load_whole_contents|
          expect(load_whole_contents.map(&:url)).not_to include(article_node2022.url)
          expect(load_whole_contents.map(&:url)).not_to include(article_page2022_1.url)
          expect(load_whole_contents.map(&:url)).not_to include(article_page2022_2.url)
          expect(load_whole_contents.map(&:url)).not_to include(article_node2023.url)
          expect(load_whole_contents.map(&:url)).not_to include(article_page2023_1.url)
          expect(load_whole_contents.map(&:url)).not_to include(article_page2023_2.url)
        end
      end
    end

    context 'on the subdir site' do
      let!(:parent_site) { cms_site }
      let!(:site) { create :cms_site_subdir, parent: parent_site }
      let!(:article_node) { create :article_node_page, cur_site: site }
      let!(:article_page1) { create :article_page, cur_site: site, cur_node: article_node }
      let!(:article_page2) { create :article_page, cur_site: site, cur_node: article_node }
      let!(:node) { create :sitemap_node_page, cur_site: site }

      context "sitemap_deny_urls requires site's subdir to exclude the specific nodes / pages" do
        let!(:item) do
          create(
            :sitemap_page, cur_site: site, cur_node: node, sitemap_page_state: 'show',
            sitemap_deny_urls: [ "/#{site.subdir}/#{article_node.filename}/" ])
        end
        subject! { Sitemap::RenderService.new(cur_site: site, cur_node: node, page: item) }

        it do
          subject.load_whole_contents.tap do |load_whole_contents|
            expect(load_whole_contents.map(&:url)).not_to include(article_node.url)
            expect(load_whole_contents.map(&:url)).not_to include(article_page1.url)
            expect(load_whole_contents.map(&:url)).not_to include(article_page2.url)
          end
        end
      end

      context "unable to exclude the specific nodes / pages if subdir is omitted" do
        let!(:item) do
          create(
            :sitemap_page, cur_site: site, cur_node: node, sitemap_page_state: 'show',
            sitemap_deny_urls: [ "/#{article_node.filename}/" ])
        end
        subject! { Sitemap::RenderService.new(cur_site: site, cur_node: node, page: item) }

        it do
          subject.load_whole_contents.tap do |load_whole_contents|
            expect(load_whole_contents.map(&:url)).to include(article_node.url)
            expect(load_whole_contents.map(&:url)).to include(article_page1.url)
            expect(load_whole_contents.map(&:url)).to include(article_page2.url)
          end
        end
      end
    end

    context 'when banner page given' do
      let!(:banner_node) { create :ads_node_banner }
      let!(:banner_page1) { create :ads_banner, cur_node: banner_node }
      let!(:banner_page2) { create :ads_banner, cur_node: banner_node }
      let!(:node) { create :sitemap_node_page }
      let!(:item) { create(:sitemap_page, cur_node: node, sitemap_page_state: 'show') }
      subject! { Sitemap::RenderService.new(cur_site: cms_site, cur_node: node, page: item) }

      it do
        # 広告バナーページは常に含まれない
        expect(subject.load_whole_contents.map(&:url)).not_to include(banner_page1.url)
        expect(subject.load_whole_contents.map(&:url)).not_to include(banner_page2.url)
      end
    end
  end

  context "with ical event page" do
    let!(:site) { cms_site }
    let!(:user) { cms_user }
    # let!(:cate) { create :category_node_page, cur_site: site }
    let!(:event_node) do
      create(
        :event_node_page, cur_site: site, site: site, ical_refresh_method: 'auto',
        ical_import_url: unique_url)
    end
    let!(:sitemap_node) { create :sitemap_node_page, cur_site: site }
    let!(:sitemap_page) { create :sitemap_page, cur_site: site, cur_node: sitemap_node, sitemap_page_state: 'show' }

    before do
      WebMock.reset!

      body = File.read("#{Rails.root}/spec/fixtures/event/ical/event-1.ics")
      stub_request(:get, event_node.ical_import_url)
        .to_return(status: 200, body: body, headers: {})
    end

    it do
      expect do
        ss_perform_now(Event::Ical::ImportJob.bind(site_id: site.id, node_id: event_node.id, user_id: user.id))
      end.to output(include("there are 1 calendars.\n")).to_stdout

      expect(Event::Page.all.count).to eq 2
      event_pages = Event::Page.all.to_a
      event_pages.each do |event_page|
        expect(event_page.site_id).to eq site.id
        expect(event_page.name).to be_present
        expect(event_page.filename).to start_with("#{event_node.filename}/")
        expect(event_page.ical_link).to be_present
      end

      service = Sitemap::RenderService.new(cur_site: site, cur_node: sitemap_node, page: sitemap_page)
      service.load_whole_contents.tap do |load_whole_contents|
        expect(load_whole_contents).to have(5).items

        urls = load_whole_contents.map(&:url)
        expect(urls).to include(event_pages[0].ical_link, event_pages[1].ical_link)
      end
    end
  end
end
