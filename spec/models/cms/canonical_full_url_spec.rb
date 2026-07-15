require 'spec_helper'

describe Cms, type: :model, dbscope: :example do
  let!(:site) { cms_site }

  describe ".canonical_full_url" do
    context "with regular pages" do
      it do
        "/news/".tap do |request_path|
          request = ActionDispatch::Request.new(
            "rack.input" => "",
            "REQUEST_METHOD" => "GET",
            "PATH_INFO" => request_path
          )
          expect(Cms.canonical_full_url(site, request)).to eq "#{site.full_root_url}news/"
        end

        "/news/index.html".tap do |request_path|
          request = ActionDispatch::Request.new(
            "rack.input" => "",
            "REQUEST_METHOD" => "GET",
            "PATH_INFO" => request_path
          )
          expect(Cms.canonical_full_url(site, request)).to eq "#{site.full_root_url}news/"
        end

        "/news".tap do |request_path|
          request = ActionDispatch::Request.new(
            "rack.input" => "",
            "REQUEST_METHOD" => "GET",
            "PATH_INFO" => request_path
          )
          expect(Cms.canonical_full_url(site, request)).to eq "#{site.full_root_url}news/"
        end

        "/news/index.p2.html".tap do |request_path|
          request = ActionDispatch::Request.new(
            "rack.input" => "",
            "REQUEST_METHOD" => "GET",
            "PATH_INFO" => request_path
          )
          expect(Cms.canonical_full_url(site, request)).to eq "#{site.full_root_url}news/index.p2.html"
        end

        "/docs/926.html".tap do |request_path|
          request = ActionDispatch::Request.new(
            "rack.input" => "",
            "REQUEST_METHOD" => "GET",
            "PATH_INFO" => request_path
          )
          expect(Cms.canonical_full_url(site, request)).to eq "#{site.full_root_url}docs/926.html"
        end
      end
    end

    context "with 404" do
      it do
        # ルートの 404.html は 404 エラーのためのページ
        # このページは canonical を出力しない
        "/404.html".tap do |request_path|
          request = ActionDispatch::Request.new(
            "rack.input" => "",
            "REQUEST_METHOD" => "GET",
            "PATH_INFO" => request_path
          )
          expect(Cms.canonical_full_url(site, request)).to be_blank
        end

        # それ以外の 404.html は通常の記事ページ
        # このページは canonical を出力する
        "/docs/404.html".tap do |request_path|
          request = ActionDispatch::Request.new(
            "rack.input" => "",
            "REQUEST_METHOD" => "GET",
            "PATH_INFO" => request_path
          )
          expect(Cms.canonical_full_url(site, request)).to eq "#{site.full_root_url}docs/404.html"
        end
      end
    end

    context "with calendar" do
      it do
        "/calendar/".tap do |request_path|
          request = ActionDispatch::Request.new(
            "rack.input" => "",
            "REQUEST_METHOD" => "GET",
            "PATH_INFO" => request_path,
            "ss.canonical_path" => "/calendar/202607/table.html"
          )
          expect(Cms.canonical_full_url(site, request)).to eq "#{site.full_root_url}calendar/202607/table.html"
        end
      end
    end

    context "with none" do
      it do
        "/news/".tap do |request_path|
          request = ActionDispatch::Request.new(
            "rack.input" => "",
            "REQUEST_METHOD" => "GET",
            "PATH_INFO" => request_path,
            "ss.canonical_path" => :none
          )
          expect(Cms.canonical_full_url(site, request)).to be_blank
        end
      end
    end

    context "with ad page" do
      it do
        "/ad/page30.html?redirect=/kurashi/".tap do |request_path|
          request = ActionDispatch::Request.new(
            "rack.input" => "",
            "REQUEST_METHOD" => "GET",
            "PATH_INFO" => request_path
          )
          expect(Cms.canonical_full_url(site, request)).to eq "#{site.full_root_url}ad/page30.html?redirect=/kurashi/"
        end
      end
    end
  end
end
