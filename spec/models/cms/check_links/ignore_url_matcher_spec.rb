require 'spec_helper'

describe Cms::CheckLinks::IgnoreUrlMatcher, type: :model, dbscope: :example do
  let!(:site) { cms_site }

  context "when 'all' is set to kind" do
    # このケースでは自サイトのパスにのみマッチする
    context "when just path is given" do
      let(:name) { "/#{unique_id}" }
      let!(:ignore_url) { create :check_links_ignore_url, site: site, kind: 'all', name: name }
      subject! { described_class.new(cur_site: site) }

      it do
        expect(subject.match?(Addressable::URI.join(site.full_url, name))).to be_truthy

        # sub path
        expect(subject.match?(Addressable::URI.join(site.full_url, "#{name}/#{unique_id}"))).to be_falsey
        # other path
        expect(subject.match?(Addressable::URI.join(site.full_url, "/#{unique_id}"))).to be_falsey
        # just site url
        expect(subject.match?(Addressable::URI.parse(site.full_url))).to be_falsey
        # same path but other site
        expect(subject.match?(Addressable::URI.join("https://#{unique_domain}/", name))).to be_falsey
      end
    end

    # このケースでは指定サイトのパスにのみマッチする
    context "when a other origin and path is given" do
      let(:host) { unique_domain }
      let(:origin) { "https://#{host}" }
      let(:path) { "/#{unique_id}" }
      let(:name) { Addressable::URI.join(origin, path).to_s }
      let!(:ignore_url) { create :check_links_ignore_url, site: site, kind: 'all', name: name }
      subject! { described_class.new(cur_site: site) }

      it do
        expect(subject.match?(Addressable::URI.parse(name))).to be_truthy

        # sub path
        expect(subject.match?(Addressable::URI.join(origin, "#{path}/#{unique_id}"))).to be_falsey
        # other path
        expect(subject.match?(Addressable::URI.join(origin, "/#{unique_id}"))).to be_falsey
        # same path but other site
        expect(subject.match?(Addressable::URI.join("https://#{unique_domain}/", path))).to be_falsey
        expect(subject.match?(Addressable::URI.join(site.full_url, path))).to be_falsey
        # different scheme
        expect(subject.match?(Addressable::URI.join("http://#{host}/", path))).to be_falsey
      end
    end

    # このケースでは指定サイトにマッチする。パスは何でも良い。
    context "when just other origin is given" do
      let(:host) { unique_domain }
      let(:origin) { "https://#{host}" }
      let!(:ignore_url) { create :check_links_ignore_url, site: site, kind: 'all', name: origin }
      subject! { described_class.new(cur_site: site) }

      it do
        expect(subject.match?(Addressable::URI.parse(origin))).to be_truthy
        expect(subject.match?(Addressable::URI.join(origin, "/#{unique_id}"))).to be_truthy

        # same path but other site
        expect(subject.match?(Addressable::URI.parse("https://#{unique_domain}/"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse(site.full_url))).to be_falsey
        # different scheme
        expect(subject.match?(Addressable::URI.parse("http://#{host}"))).to be_falsey
      end
    end

    # このケースでは指定サイトにマッチする。パスは何でも良い。スキームも何でもよい。
    context "when just other origin but scheme is missing is given" do
      let(:host) { unique_domain }
      let!(:ignore_url) { create :check_links_ignore_url, site: site, kind: 'all', name: "//#{host}" }
      subject! { described_class.new(cur_site: site) }

      it do
        expect(subject.match?(Addressable::URI.parse("http://#{host}"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://#{host}"))).to be_truthy

        # same path but other site
        expect(subject.match?(Addressable::URI.parse("https://#{unique_domain}/"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse(site.full_url))).to be_falsey
      end
    end
  end

  context "when 'start_with' is set to kind" do
    # このケースでは自サイトのパスにのみマッチする
    context "when just path is given" do
      let(:name) { "/#{unique_id}" }
      let!(:ignore_url) { create :check_links_ignore_url, site: site, kind: 'start_with', name: name }
      subject! { described_class.new(cur_site: site) }

      it do
        expect(subject.match?(Addressable::URI.join(site.full_url, name))).to be_truthy
        # sub path
        expect(subject.match?(Addressable::URI.join(site.full_url, "#{name}/#{unique_id}"))).to be_truthy

        # other path
        expect(subject.match?(Addressable::URI.join(site.full_url, "/#{unique_id}"))).to be_falsey
        # just site url
        expect(subject.match?(Addressable::URI.parse(site.full_url))).to be_falsey
        # same path but other site
        expect(subject.match?(Addressable::URI.join("https://#{unique_domain}/", name))).to be_falsey
      end
    end

    # このケースでは指定サイトのパスにのみマッチする
    context "when a other origin and path is given" do
      let(:host) { unique_domain }
      let(:origin) { "https://#{host}" }
      let(:path) { "/#{unique_id}" }
      let(:name) { Addressable::URI.join(origin, path).to_s }
      let!(:ignore_url) { create :check_links_ignore_url, site: site, kind: 'start_with', name: name }
      subject! { described_class.new(cur_site: site) }

      it do
        expect(subject.match?(Addressable::URI.parse(name))).to be_truthy
        # sub path
        expect(subject.match?(Addressable::URI.join(origin, "#{path}/#{unique_id}"))).to be_truthy

        # other path
        expect(subject.match?(Addressable::URI.join(origin, "/#{unique_id}"))).to be_falsey
        # same path but other site
        expect(subject.match?(Addressable::URI.join("https://#{unique_domain}/", path))).to be_falsey
        expect(subject.match?(Addressable::URI.join(site.full_url, path))).to be_falsey
        # different scheme
        expect(subject.match?(Addressable::URI.join("http://#{host}/", path))).to be_falsey
      end
    end

    # このケースでは指定サイトにマッチする。パスは何でも良い。
    context "when just other origin is given" do
      let(:host_start) { unique_id }
      let(:origin) { "https://#{host_start}." }
      let!(:ignore_url) { create :check_links_ignore_url, site: site, kind: 'start_with', name: origin }
      subject! { described_class.new(cur_site: site) }

      it do
        expect(subject.match?(Addressable::URI.parse("https://#{host_start}.example.jp"))).to be_truthy
        expect(subject.match?(Addressable::URI.join("https://#{host_start}.example.jp", "/#{unique_id}"))).to be_truthy

        # same path but other site
        expect(subject.match?(Addressable::URI.parse("https://#{unique_domain}/"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse(site.full_url))).to be_falsey
        # different scheme
        expect(subject.match?(Addressable::URI.parse("http://#{host_start}.example.jp"))).to be_falsey
      end
    end

    # このケースでは指定サイトにマッチする。パスは何でも良い。スキームも何でもよい。
    context "when just other origin but scheme is missing is given" do
      let(:host_start) { unique_id }
      let!(:ignore_url) { create :check_links_ignore_url, site: site, kind: 'start_with', name: "//#{host_start}." }
      subject! { described_class.new(cur_site: site) }

      it do
        expect(subject.match?(Addressable::URI.join("http://#{host_start}.example.jp", "/#{unique_id}"))).to be_truthy
        expect(subject.match?(Addressable::URI.join("https://#{host_start}.example.jp", "/#{unique_id}"))).to be_truthy

        # same path but other site
        expect(subject.match?(Addressable::URI.parse("https://#{unique_domain}/"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse(site.full_url))).to be_falsey
      end
    end
  end

  context "when 'end_with' is set to kind" do
    # このケースでは自サイトのパスにのみマッチする
    context "when just path is given" do
      let(:name) { "/#{unique_id}" }
      let!(:ignore_url) { create :check_links_ignore_url, site: site, kind: 'end_with', name: name }
      subject! { described_class.new(cur_site: site) }

      it do
        expect(subject.match?(Addressable::URI.join(site.full_url, name))).to be_truthy
        # sub path
        expect(subject.match?(Addressable::URI.join(site.full_url, "/#{unique_id}#{name}"))).to be_truthy

        # other path
        expect(subject.match?(Addressable::URI.join(site.full_url, "/#{unique_id}"))).to be_falsey
        # just site url
        expect(subject.match?(Addressable::URI.parse(site.full_url))).to be_falsey
        # same path but other site
        expect(subject.match?(Addressable::URI.join("https://#{unique_domain}/", name))).to be_falsey
      end
    end

    # このケースでは指定サイトのパスにのみマッチする
    context "when a other origin and path is given" do
      let(:host) { unique_domain }
      let(:origin) { "https://#{host}" }
      let(:path) { "/#{unique_id}" }
      let(:name) { Addressable::URI.join(origin, path).to_s }
      let!(:ignore_url) { create :check_links_ignore_url, site: site, kind: 'end_with', name: name }
      subject! { described_class.new(cur_site: site) }

      it do
        expect(subject.match?(Addressable::URI.parse(name))).to be_truthy
        # sub path
        expect(subject.match?(Addressable::URI.join(origin, "/#{unique_id}#{path}"))).to be_truthy

        # other path
        expect(subject.match?(Addressable::URI.join(origin, "/#{unique_id}"))).to be_falsey
        # same path but other site
        expect(subject.match?(Addressable::URI.join("https://#{unique_domain}/", path))).to be_falsey
        expect(subject.match?(Addressable::URI.join(site.full_url, path))).to be_falsey
        # different scheme
        expect(subject.match?(Addressable::URI.join("http://#{host}/", path))).to be_falsey
      end
    end

    # このケースでは指定サイトにマッチする。パスは何でも良い。
    context "when just other origin is given" do
      let(:host_end) { unique_id }
      let(:origin) { "https://.#{host_end}" }
      let!(:ignore_url) { create :check_links_ignore_url, site: site, kind: 'end_with', name: origin }
      subject! { described_class.new(cur_site: site) }

      it do
        expect(subject.match?(Addressable::URI.parse("https://static.#{host_end}"))).to be_truthy
        expect(subject.match?(Addressable::URI.join("https://site.#{host_end}", "/#{unique_id}"))).to be_truthy

        # same path but other site
        expect(subject.match?(Addressable::URI.parse("https://#{unique_domain}/"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse(site.full_url))).to be_falsey
        # different scheme
        expect(subject.match?(Addressable::URI.parse("http://www.#{host_end}"))).to be_falsey
      end
    end

    # このケースでは指定サイトにマッチする。パスは何でも良い。スキームも何でもよい。
    context "when just other origin but scheme is missing is given" do
      let(:host_end) { unique_id }
      let!(:ignore_url) { create :check_links_ignore_url, site: site, kind: 'end_with', name: "//.#{host_end}" }
      subject! { described_class.new(cur_site: site) }

      it do
        expect(subject.match?(Addressable::URI.join("http://static.#{host_end}", "/#{unique_id}"))).to be_truthy
        expect(subject.match?(Addressable::URI.join("https://site.#{host_end}", "/#{unique_id}"))).to be_truthy

        # same path but other site
        expect(subject.match?(Addressable::URI.parse("https://#{unique_domain}/"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse(site.full_url))).to be_falsey
      end
    end
  end

  context "when 'include' is set to kind" do
    # このケースでは自サイトのパスにのみマッチする
    context "when just path is given" do
      let(:name) { unique_id }
      let!(:ignore_url) { create :check_links_ignore_url, site: site, kind: 'include', name: name }
      subject! { described_class.new(cur_site: site) }

      it do
        expect(subject.match?(Addressable::URI.join(site.full_url, "/#{name}"))).to be_truthy
        # sub path
        expect(subject.match?(Addressable::URI.join(site.full_url, "/#{unique_id}/#{name}"))).to be_truthy
        expect(subject.match?(Addressable::URI.join(site.full_url, "/#{name}/#{unique_id}"))).to be_truthy

        # other path
        expect(subject.match?(Addressable::URI.join(site.full_url, "/#{unique_id}"))).to be_falsey
        # just site url
        expect(subject.match?(Addressable::URI.parse(site.full_url))).to be_falsey
        # same path but other site
        expect(subject.match?(Addressable::URI.join("https://#{unique_domain}/", name))).to be_falsey
      end
    end

    # このケースでは指定サイトにマッチする。パスは何でも良い。スキームも何でもよい。
    context "when just other origin but scheme is missing is given" do
      let(:host_include) { unique_id }
      let!(:ignore_url) { create :check_links_ignore_url, site: site, kind: 'include', name: "//#{host_include}" }
      subject! { described_class.new(cur_site: site) }

      it do
        expect(subject.match?(Addressable::URI.join("http://static.#{host_include}.com", "/#{unique_id}"))).to be_truthy
        expect(subject.match?(Addressable::URI.join("https://site.#{host_include}.jp", "/#{unique_id}"))).to be_truthy

        # same path but other site
        expect(subject.match?(Addressable::URI.parse("https://#{unique_domain}/"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse(site.full_url))).to be_falsey
      end
    end
  end

  context "when email is given" do
    subject! { described_class.new(cur_site: site) }

    it do
      expect(subject.match?(Addressable::URI.parse("mailto:#{unique_email}"))).to be_truthy
    end
  end

  context "when assets path is given" do
    subject! { described_class.new(cur_site: site) }

    it do
      expect(subject.match?(Addressable::URI.join(site.full_url, "/assets/public/style.css"))).to be_truthy
      expect(subject.match?(Addressable::URI.join(site.full_url, "/assets/public/script.js"))).to be_truthy
    end
  end

  context "when pagination path is given" do
    subject! { described_class.new(cur_site: site) }

    it do
      expect(subject.match?(Addressable::URI.join(site.full_url, "/docs/index.p2.html"))).to be_truthy
    end
  end

  # context "when calendar path is given" do
  #   subject! { described_class.new(cur_site: site) }
  #
  #   it do
  #     expect(subject.match?(Addressable::URI.join(site.full_url, "/calendar/202601/index.html"))).to be_truthy
  #     expect(subject.match?(Addressable::URI.join(site.full_url, "/calendar/202602/list.html"))).to be_truthy
  #     expect(subject.match?(Addressable::URI.join(site.full_url, "/calendar/202603/map.html"))).to be_truthy
  #   end
  # end

  context "when sns share path is given" do
    subject! { described_class.new(cur_site: site) }

    it do
      expect(subject.match?(Addressable::URI.parse("https://twitter.com/share"))).to be_truthy
      url = "https://b.hatena.ne.jp/entry/https://demo.ss-proj.org/docs/page30.html"
      expect(subject.match?(Addressable::URI.parse(url))).to be_truthy
      url = "https://b.hatena.ne.jp/entry/#{CGI.escape("https://demo.ss-proj.org/docs/page30.html")}"
      expect(subject.match?(Addressable::URI.parse(url))).to be_truthy
    end
  end
end
