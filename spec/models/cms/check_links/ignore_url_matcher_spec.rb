require 'spec_helper'

describe Cms::CheckLinks::IgnoreUrlMatcher, type: :model, dbscope: :example do
  let!(:site0) { cms_site }
  let!(:site) { create :cms_site_unique, domains: %w(ss1.example.jp ss2.example.jp) }

  context "when 'all' is set to kind" do
    # このケースでは自サイトのパスにのみマッチする
    context "when just path is given #1" do
      let!(:ignore_url) { create :check_links_ignore_url, site: site, kind: 'all', name: "/path1" }
      subject! { described_class.new(cur_site: site) }

      it do
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/path1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("http://ss2.example.jp/path1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://ss1.example.jp/path1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://ss2.example.jp/path1"))).to be_truthy
        # /path1 と /path1/ は同じ
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/path1/"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("http://ss2.example.jp/path1/"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://ss1.example.jp/path1/"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://ss2.example.jp/path1/"))).to be_truthy
        # クエリが付いていてもパスが同じならok
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/path1?group=1&page=1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("http://ss2.example.jp/path1?group=1&page=1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://ss1.example.jp/path1/?group=1&page=1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://ss2.example.jp/path1/?group=1&page=1"))).to be_truthy

        # sub path
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/path1/#{unique_id}"))).to be_falsey
        # other path
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/path2"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/path2/"))).to be_falsey
        # just site url
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/"))).to be_falsey
        # same path but other site
        expect(subject.match?(Addressable::URI.parse("https://#{unique_domain}/path1"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse("https://#{unique_domain}/path1/"))).to be_falsey
      end
    end

    context "when just path is given #2" do
      # path1 は /path1 と見なされる
      let!(:ignore_url) { create :check_links_ignore_url, site: site, kind: 'all', name: "path1" }
      subject! { described_class.new(cur_site: site) }

      it do
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/path1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("http://ss2.example.jp/path1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://ss1.example.jp/path1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://ss2.example.jp/path1"))).to be_truthy
        # /path1 と /path1/ は同じ
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/path1/"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("http://ss2.example.jp/path1/"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://ss1.example.jp/path1/"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://ss2.example.jp/path1/"))).to be_truthy
        # クエリが付いていてもパスが同じならok
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/path1?group=1&page=1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("http://ss2.example.jp/path1?group=1&page=1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://ss1.example.jp/path1/?group=1&page=1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://ss2.example.jp/path1/?group=1&page=1"))).to be_truthy

        # sub path
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/path1/#{unique_id}"))).to be_falsey
        # other path
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/path2"))).to be_falsey
        # just site url
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/"))).to be_falsey
        # same path but other site
        expect(subject.match?(Addressable::URI.parse("https://#{unique_domain}/path1"))).to be_falsey
      end
    end

    context "when just path is given #3" do
      let!(:ignore_url) { create :check_links_ignore_url, site: site, kind: 'all', name: "/path1/" }
      subject! { described_class.new(cur_site: site) }

      it do
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/path1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("http://ss2.example.jp/path1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://ss1.example.jp/path1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://ss2.example.jp/path1"))).to be_truthy
        # /path1 と /path1/ は同じ
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/path1/"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("http://ss2.example.jp/path1/"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://ss1.example.jp/path1/"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://ss2.example.jp/path1/"))).to be_truthy
        # クエリが付いていてもパスが同じならok
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/path1?group=1&page=1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("http://ss2.example.jp/path1?group=1&page=1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://ss1.example.jp/path1/?group=1&page=1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://ss2.example.jp/path1/?group=1&page=1"))).to be_truthy

        # sub path
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/path1/#{unique_id}"))).to be_falsey
        # other path
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/path2"))).to be_falsey
        # just site url
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/"))).to be_falsey
        # same path but other site
        expect(subject.match?(Addressable::URI.parse("https://#{unique_domain}/path1"))).to be_falsey
      end
    end

    context "when path and queries are given #1" do
      let!(:ignore_url) { create :check_links_ignore_url, site: site, kind: 'all', name: "/path1?group=1&page=1" }
      subject! { described_class.new(cur_site: site) }

      it do
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/path1?group=1&page=1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("http://ss2.example.jp/path1?group=1&page=1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://ss1.example.jp/path1?group=1&page=1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://ss2.example.jp/path1?group=1&page=1"))).to be_truthy
        # /path1 と /path1/ は同じ
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/path1/?group=1&page=1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("http://ss2.example.jp/path1/?group=1&page=1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://ss1.example.jp/path1/?group=1&page=1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://ss2.example.jp/path1/?group=1&page=1"))).to be_truthy

        # クエリが付いていない
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/path1"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse("http://ss2.example.jp/path1"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse("https://ss1.example.jp/path1/"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse("https://ss2.example.jp/path1/"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/path1?"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse("http://ss2.example.jp/path1?"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse("https://ss1.example.jp/path1/?"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse("https://ss2.example.jp/path1/?"))).to be_falsey
        # クエリが異なる
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/path1?group=1&page=2"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse("http://ss2.example.jp/path1?group=1&page=2"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse("https://ss1.example.jp/path1/?group=2&page=1"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse("https://ss2.example.jp/path1/?group=2&page=1"))).to be_falsey
        # クエリの順番が異なる
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/path1?page=1&group=1"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse("http://ss2.example.jp/path1?page=1&group=1"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse("https://ss1.example.jp/path1/?page=1&group=1"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse("https://ss2.example.jp/path1/?page=1&group=1"))).to be_falsey
        # クエリに余計なものが付く
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/path1?group=1&page=1&key=value"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse("http://ss2.example.jp/path1?group=1&page=1&key=value"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse("https://ss1.example.jp/path1/?group=1&page=1&key=value"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse("https://ss2.example.jp/path1/?group=1&page=1&key=value"))).to be_falsey
      end
    end

    context "when path and queries are given #2" do
      # "/path1?group=1&page=1" と "/path1/?group=1&page=1" は同じ
      let!(:ignore_url) { create :check_links_ignore_url, site: site, kind: 'all', name: "/path1/?group=1&page=1" }
      subject! { described_class.new(cur_site: site) }

      it do
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/path1?group=1&page=1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("http://ss2.example.jp/path1?group=1&page=1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://ss1.example.jp/path1?group=1&page=1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://ss2.example.jp/path1?group=1&page=1"))).to be_truthy
        # /path1 と /path1/ は同じ
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/path1/?group=1&page=1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("http://ss2.example.jp/path1/?group=1&page=1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://ss1.example.jp/path1/?group=1&page=1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://ss2.example.jp/path1/?group=1&page=1"))).to be_truthy

        # クエリが付いていない
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/path1"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse("http://ss2.example.jp/path1"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse("https://ss1.example.jp/path1/"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse("https://ss2.example.jp/path1/"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/path1?"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse("http://ss2.example.jp/path1?"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse("https://ss1.example.jp/path1/?"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse("https://ss2.example.jp/path1/?"))).to be_falsey
        # クエリが異なる
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/path1?group=1&page=2"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse("http://ss2.example.jp/path1?group=1&page=2"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse("https://ss1.example.jp/path1/?group=2&page=1"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse("https://ss2.example.jp/path1/?group=2&page=1"))).to be_falsey
        # クエリの順番が異なる
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/path1?page=1&group=1"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse("http://ss2.example.jp/path1?page=1&group=1"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse("https://ss1.example.jp/path1/?page=1&group=1"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse("https://ss2.example.jp/path1/?page=1&group=1"))).to be_falsey
        # クエリに余計なものが付く
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/path1?group=1&page=1&key=value"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse("http://ss2.example.jp/path1?group=1&page=1&key=value"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse("https://ss1.example.jp/path1/?group=1&page=1&key=value"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse("https://ss2.example.jp/path1/?group=1&page=1&key=value"))).to be_falsey
      end
    end

    context "when path and queries are given #3" do
      let!(:ignore_url) { create :check_links_ignore_url, site: site, kind: 'all', name: "/path1?" }
      subject! { described_class.new(cur_site: site) }

      it do
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/path1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("http://ss2.example.jp/path1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://ss1.example.jp/path1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://ss2.example.jp/path1"))).to be_truthy
        # /path1 と /path1/ は同じ
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/path1/"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("http://ss2.example.jp/path1/"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://ss1.example.jp/path1/"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://ss2.example.jp/path1/"))).to be_truthy
        # このケースではクエリが空の場合にのみマッチする
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/path1?"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("http://ss2.example.jp/path1?"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://ss1.example.jp/path1/?"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://ss2.example.jp/path1/?"))).to be_truthy

        # このケースではクエリが空の場合にのみマッチする
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/path1?group=1&page=1"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse("http://ss2.example.jp/path1?group=1&page=1"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse("https://ss1.example.jp/path1/?group=1&page=1"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse("https://ss2.example.jp/path1/?group=1&page=1"))).to be_falsey
        # sub path
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/path1/#{unique_id}"))).to be_falsey
        # other path
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/path2"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/path2/"))).to be_falsey
        # just site url
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/"))).to be_falsey
        # same path but other site
        expect(subject.match?(Addressable::URI.parse("https://#{unique_domain}/path1"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse("https://#{unique_domain}/path1/"))).to be_falsey
      end
    end

    # このケースでは指定サイトのパスにのみマッチする
    context "when a other origin and path is given #1" do
      let!(:ignore_url) { create :check_links_ignore_url, site: site, kind: 'all', name: "https://sample1.example.jp/path1" }
      subject! { described_class.new(cur_site: site) }

      it do
        expect(subject.match?(Addressable::URI.parse("https://sample1.example.jp/path1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://sample1.example.jp/path1/"))).to be_truthy

        # sub path
        expect(subject.match?(Addressable::URI.parse("https://sample1.example.jp/path1/#{unique_id}"))).to be_falsey
        # other path
        expect(subject.match?(Addressable::URI.parse("https://sample1.example.jp/path2"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse("https://sample1.example.jp/path2/"))).to be_falsey
        # same path but other site
        expect(subject.match?(Addressable::URI.parse("https://sample2.example.jp/path1"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse("https://sample2.example.jp/path1/"))).to be_falsey
        # different scheme
        expect(subject.match?(Addressable::URI.parse("http://sample1.example.jp/path1"))).to be_falsey
      end
    end

    context "when a other origin and path is given #2" do
      # /path1 と /path1/ は同じ
      let!(:ignore_url) { create :check_links_ignore_url, site: site, kind: 'all', name: "https://sample1.example.jp/path1/" }
      subject! { described_class.new(cur_site: site) }

      it do
        expect(subject.match?(Addressable::URI.parse("https://sample1.example.jp/path1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://sample1.example.jp/path1/"))).to be_truthy

        # sub path
        expect(subject.match?(Addressable::URI.parse("https://sample1.example.jp/path1/#{unique_id}"))).to be_falsey
        # other path
        expect(subject.match?(Addressable::URI.parse("https://sample1.example.jp/path2"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse("https://sample1.example.jp/path2/"))).to be_falsey
        # same path but other site
        expect(subject.match?(Addressable::URI.parse("https://sample2.example.jp/path1"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse("https://sample2.example.jp/path1/"))).to be_falsey
        # different scheme
        expect(subject.match?(Addressable::URI.parse("http://sample1.example.jp/path1"))).to be_falsey
      end
    end

    # このケースでは指定サイトにマッチする。パスは何でも良い。
    context "when just other origin is given #1" do
      let!(:ignore_url) { create :check_links_ignore_url, site: site, kind: 'all', name: "https://sample1.example.jp" }
      subject! { described_class.new(cur_site: site) }

      it do
        expect(subject.match?(Addressable::URI.parse("https://sample1.example.jp"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://sample1.example.jp/"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://sample1.example.jp/path1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://sample1.example.jp/path1/"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://sample1.example.jp/path1/#{unique_id}.html"))).to be_truthy

        # same path but other site
        expect(subject.match?(Addressable::URI.parse("https://sample2.example.jp"))).to be_falsey
        # different scheme
        expect(subject.match?(Addressable::URI.parse("http://sample1.example.jp"))).to be_falsey
      end
    end

    context "when just other origin is given #2" do
      # https://sample1.example.jp と https://sample1.example.jp/ は同じ
      let!(:ignore_url) { create :check_links_ignore_url, site: site, kind: 'all', name: "https://sample1.example.jp/" }
      subject! { described_class.new(cur_site: site) }

      it do
        expect(subject.match?(Addressable::URI.parse("https://sample1.example.jp"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://sample1.example.jp/"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://sample1.example.jp/path1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://sample1.example.jp/path1/"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://sample1.example.jp/path1/#{unique_id}.html"))).to be_truthy

        # same path but other site
        expect(subject.match?(Addressable::URI.parse("https://sample2.example.jp"))).to be_falsey
        # different scheme
        expect(subject.match?(Addressable::URI.parse("http://sample1.example.jp"))).to be_falsey
      end
    end

    # このケースでは指定サイトにマッチする。パスは何でも良い。スキームも何でもよい。
    context "when just other origin but scheme is missing is given #1" do
      let!(:ignore_url) { create :check_links_ignore_url, site: site, kind: 'all', name: "//sample1.example.jp" }
      subject! { described_class.new(cur_site: site) }

      it do
        expect(subject.match?(Addressable::URI.parse("http://sample1.example.jp"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://sample1.example.jp"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("http://sample1.example.jp/"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://sample1.example.jp/"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("http://sample1.example.jp/path1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://sample1.example.jp/path1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("http://sample1.example.jp/path1/"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://sample1.example.jp/path1/"))).to be_truthy

        # same path but other site
        expect(subject.match?(Addressable::URI.parse("https://sample2.example.jp"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse("https://sample2.example.jp/"))).to be_falsey
      end
    end

    # このケースでは指定サイトにマッチする。パスは何でも良い。スキームも何でもよい。
    context "when just other origin but scheme is missing is given #2" do
      # "//sample1.example.jp" と "//sample1.example.jp/" は同じ
      let!(:ignore_url) { create :check_links_ignore_url, site: site, kind: 'all', name: "//sample1.example.jp/" }
      subject! { described_class.new(cur_site: site) }

      it do
        expect(subject.match?(Addressable::URI.parse("http://sample1.example.jp"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://sample1.example.jp"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("http://sample1.example.jp/"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://sample1.example.jp/"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("http://sample1.example.jp/path1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://sample1.example.jp/path1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("http://sample1.example.jp/path1/"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://sample1.example.jp/path1/"))).to be_truthy

        # same path but other site
        expect(subject.match?(Addressable::URI.parse("https://sample2.example.jp"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse("https://sample2.example.jp/"))).to be_falsey
      end
    end
  end

  context "when 'start_with' is set to kind" do
    # このケースでは自サイトのパスにのみマッチする
    context "when just path is given #1" do
      let!(:ignore_url) { create :check_links_ignore_url, site: site, kind: 'start_with', name: "/path1" }
      subject! { described_class.new(cur_site: site) }

      it do
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/path1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/path1/"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("http://ss2.example.jp/path1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("http://ss2.example.jp/path1/"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://ss1.example.jp/path1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://ss1.example.jp/path1/"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://ss2.example.jp/path1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://ss2.example.jp/path1/"))).to be_truthy
        # sub path
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/path1/#{unique_id}"))).to be_truthy

        # other path
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/path2"))).to be_falsey
        # just site url
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/"))).to be_falsey
        # same path but other site
        expect(subject.match?(Addressable::URI.parse("https://#{unique_domain}/path1"))).to be_falsey
      end
    end

    context "when just path is given #2" do
      # /path1 と path1 は同じ
      let!(:ignore_url) { create :check_links_ignore_url, site: site, kind: 'start_with', name: "path1" }
      subject! { described_class.new(cur_site: site) }

      it do
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/path1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/path1/"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("http://ss2.example.jp/path1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("http://ss2.example.jp/path1/"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://ss1.example.jp/path1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://ss1.example.jp/path1/"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://ss2.example.jp/path1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://ss2.example.jp/path1/"))).to be_truthy
        # sub path
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/path1/#{unique_id}"))).to be_truthy

        # other path
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/path2"))).to be_falsey
        # just site url
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/"))).to be_falsey
        # same path but other site
        expect(subject.match?(Addressable::URI.parse("https://#{unique_domain}/path1"))).to be_falsey
      end
    end

    # このケースでは指定サイトのパスにのみマッチする
    context "when a other origin and path is given" do
      let!(:ignore_url) { create :check_links_ignore_url, site: site, kind: 'start_with', name: "https://sample1.example.jp/path1" }
      subject! { described_class.new(cur_site: site) }

      it do
        expect(subject.match?(Addressable::URI.parse("https://sample1.example.jp/path1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://sample1.example.jp/path1/"))).to be_truthy
        # sub path
        expect(subject.match?(Addressable::URI.parse("https://sample1.example.jp/path1/#{unique_id}"))).to be_truthy

        # other path
        expect(subject.match?(Addressable::URI.parse("https://sample1.example.jp/path2"))).to be_falsey
        # same path but other site
        expect(subject.match?(Addressable::URI.parse("https://sample2.example.jp/path1"))).to be_falsey
        # different scheme
        expect(subject.match?(Addressable::URI.parse("http://sample1.example.jp/path1"))).to be_falsey
      end
    end

    # このケースでは指定サイトにマッチする。パスは何でも良い。
    context "when just other origin is given" do
      let!(:ignore_url) { create :check_links_ignore_url, site: site, kind: 'start_with', name: "https://sample1.example." }
      subject! { described_class.new(cur_site: site) }

      it do
        expect(subject.match?(Addressable::URI.parse("https://sample1.example.jp"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://sample1.example.jp/"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://sample1.example.jp/path1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://sample1.example.jp/path1/"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://sample1.example.com"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://sample1.example.com/"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://sample1.example.com/path1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://sample1.example.com/path1/"))).to be_truthy

        # same path but other site
        expect(subject.match?(Addressable::URI.parse("https://sample2.example.jp"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse("https://sample2.example.jp/"))).to be_falsey
        # different scheme
        expect(subject.match?(Addressable::URI.parse("http://sample1.example.jp"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse("http://sample1.example.jp/"))).to be_falsey
      end
    end

    # このケースでは指定サイトにマッチする。パスは何でも良い。スキームも何でもよい。
    context "when just other origin but scheme is missing is given" do
      let!(:ignore_url) { create :check_links_ignore_url, site: site, kind: 'start_with', name: "//sample1.example." }
      subject! { described_class.new(cur_site: site) }

      it do
        expect(subject.match?(Addressable::URI.parse("http://sample1.example.jp"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("http://sample1.example.jp/"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("http://sample1.example.jp/path1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://sample1.example.com"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://sample1.example.com/"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://sample1.example.com/path1"))).to be_truthy

        # same path but other site
        expect(subject.match?(Addressable::URI.parse("https://sample2.example.jp"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse("https://sample2.example.jp/"))).to be_falsey
      end
    end
  end

  context "when 'end_with' is set to kind" do
    # このケースでは自サイトのパスにのみマッチする
    context "when just path is given #1" do
      let!(:ignore_url) { create :check_links_ignore_url, site: site, kind: 'end_with', name: "/path1" }
      subject! { described_class.new(cur_site: site) }

      it do
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/path1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("http://ss2.example.jp/path1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://ss1.example.jp/path1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://ss2.example.jp/path1"))).to be_truthy
        # sub path
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/#{unique_id}/path1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("http://ss2.example.jp/#{unique_id}/path1"))).to be_truthy

        # other path
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/path2"))).to be_falsey
        # just site url
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/"))).to be_falsey
        # same path but other site
        expect(subject.match?(Addressable::URI.parse("https://#{unique_domain}/path1"))).to be_falsey
      end
    end

    context "when just path is given #2" do
      # /path と path はほぼ同じ。
      let!(:ignore_url) { create :check_links_ignore_url, site: site, kind: 'end_with', name: "path1" }
      subject! { described_class.new(cur_site: site) }

      it do
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/path1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("http://ss2.example.jp/path1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://ss1.example.jp/path1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://ss2.example.jp/path1"))).to be_truthy
        # sub path
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/#{unique_id}/path1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("http://ss2.example.jp/#{unique_id}/path1"))).to be_truthy

        # other path
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/path2"))).to be_falsey
        # just site url
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/"))).to be_falsey
        # same path but other site
        expect(subject.match?(Addressable::URI.parse("https://#{unique_domain}/path1"))).to be_falsey
      end
    end

    # このケースの動作として何が良いのか不明。よって動作は未定義としたい。
    xcontext "when a other origin and path is given" do
      let!(:ignore_url) { create :check_links_ignore_url, site: site, kind: 'end_with', name: "https://sample1.example.jp/path1" }
      subject! { described_class.new(cur_site: site) }

      it do
        expect(subject.match?(Addressable::URI.parse("https://sample1.example.jp/path1"))).to be_truthy
        # sub path
        expect(subject.match?(Addressable::URI.parse("https://sample1.example.jp/#{unique_id}/path1"))).to be_truthy

        # other path
        expect(subject.match?(Addressable::URI.parse("https://sample1.example.jp/#{unique_id}"))).to be_falsey
        # same path but other site
        expect(subject.match?(Addressable::URI.parse("https://sample2.example.jp/path2"))).to be_falsey
        # different scheme
        expect(subject.match?(Addressable::URI.parse("http://sample1.example.jp/path1"))).to be_falsey
      end
    end

    # このケースでは指定サイトにマッチする。パスは何でも良い。
    context "when just other origin is given #1" do
      let!(:ignore_url) { create :check_links_ignore_url, site: site, kind: 'end_with', name: "https://.example.jp" }
      subject! { described_class.new(cur_site: site) }

      it do
        expect(subject.match?(Addressable::URI.parse("https://static.example.jp"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://static.example.jp/"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://site.example.jp/path1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://site.example.jp/path1/"))).to be_truthy

        # same path but other site
        expect(subject.match?(Addressable::URI.parse("https://sample1.example.com"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse("https://sample1.example.com/"))).to be_falsey
        # different scheme
        expect(subject.match?(Addressable::URI.parse("http://static.example.jp"))).to be_falsey
      end
    end

    context "when just other origin is given #2" do
      # "https://.example.jp" と "https://.example.jp/" は同じ
      let!(:ignore_url) { create :check_links_ignore_url, site: site, kind: 'end_with', name: "https://.example.jp/" }
      subject! { described_class.new(cur_site: site) }

      it do
        expect(subject.match?(Addressable::URI.parse("https://static.example.jp"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://static.example.jp/"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://site.example.jp/path1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://site.example.jp/path1/"))).to be_truthy

        # same path but other site
        expect(subject.match?(Addressable::URI.parse("https://sample1.example.com"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse("https://sample1.example.com/"))).to be_falsey
        # different scheme
        expect(subject.match?(Addressable::URI.parse("http://static.example.jp"))).to be_falsey
      end
    end

    # このケースでは指定サイトにマッチする。パスは何でも良い。スキームも何でもよい。
    context "when just other origin but scheme is missing is given #1" do
      let!(:ignore_url) { create :check_links_ignore_url, site: site, kind: 'end_with', name: "//.example.jp" }
      subject! { described_class.new(cur_site: site) }

      it do
        expect(subject.match?(Addressable::URI.parse("http://static.example.jp"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("http://static.example.jp/"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("http://static.example.jp/path1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("http://static.example.jp/path1/"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://site.example.jp/#{unique_id}"))).to be_truthy

        # same path but other site
        expect(subject.match?(Addressable::URI.parse("http://static.example.com"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse("http://static.example.com/"))).to be_falsey
      end
    end

    context "when just other origin but scheme is missing is given #2" do
      # "//.example.jp" と "//.example.jp/" は同じ
      let!(:ignore_url) { create :check_links_ignore_url, site: site, kind: 'end_with', name: "//.example.jp/" }
      subject! { described_class.new(cur_site: site) }

      it do
        expect(subject.match?(Addressable::URI.parse("http://static.example.jp"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("http://static.example.jp/"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("http://static.example.jp/path1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("http://static.example.jp/path1/"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://site.example.jp/#{unique_id}"))).to be_truthy

        # same path but other site
        expect(subject.match?(Addressable::URI.parse("http://static.example.com"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse("http://static.example.com/"))).to be_falsey
      end
    end
  end

  context "when 'include' is set to kind" do
    # このケースでは自サイトのパスにのみマッチする
    context "when just path is given #1" do
      let(:name) { unique_id }
      let!(:ignore_url) { create :check_links_ignore_url, site: site, kind: 'include', name: "path1" }
      subject! { described_class.new(cur_site: site) }

      it do
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/path1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("http://ss2.example.jp/path1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://ss1.example.jp/path1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://ss2.example.jp/path1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/path1/"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("http://ss2.example.jp/path1/"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://ss1.example.jp/path1/"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://ss2.example.jp/path1/"))).to be_truthy
        # sub path
        expect(subject.match?(Addressable::URI.parse("https://ss1.example.jp/#{unique_id}/path1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://ss2.example.jp/path1/#{unique_id}"))).to be_truthy

        # other path
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/path2"))).to be_falsey
        # just site url
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/"))).to be_falsey
        # same path but other site
        expect(subject.match?(Addressable::URI.parse("http://sample1.example.jp/path1"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse("http://path1.example.jp/"))).to be_falsey
      end
    end

    context "when just path is given #2" do
      let(:name) { unique_id }
      let!(:ignore_url) { create :check_links_ignore_url, site: site, kind: 'include', name: "/path1" }
      subject! { described_class.new(cur_site: site) }

      it do
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/path1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("http://ss2.example.jp/path1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://ss1.example.jp/path1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://ss2.example.jp/path1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/path1/"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("http://ss2.example.jp/path1/"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://ss1.example.jp/path1/"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://ss2.example.jp/path1/"))).to be_truthy
        # sub path
        expect(subject.match?(Addressable::URI.parse("https://ss1.example.jp/#{unique_id}/path1"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("https://ss2.example.jp/path1/#{unique_id}"))).to be_truthy

        # other path
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/path2"))).to be_falsey
        # just site url
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse("http://ss1.example.jp/"))).to be_falsey
        # same path but other site
        expect(subject.match?(Addressable::URI.parse("http://sample1.example.jp/path1"))).to be_falsey
        expect(subject.match?(Addressable::URI.parse("http://path1.example.jp/"))).to be_falsey
      end
    end

    # このケースでは指定サイトにマッチする。パスは何でも良い。スキームも何でもよい。
    context "when just other origin but scheme is missing is given" do
      let!(:ignore_url) { create :check_links_ignore_url, site: site, kind: 'include', name: "//sample1" }
      subject! { described_class.new(cur_site: site) }

      it do
        expect(subject.match?(Addressable::URI.parse("https://sample1.example.jp"))).to be_truthy
        expect(subject.match?(Addressable::URI.parse("http://static.sample1.com/"))).to be_truthy

        # same path but other site
        expect(subject.match?(Addressable::URI.parse("https://www.example.jp/sample1"))).to be_falsey
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
