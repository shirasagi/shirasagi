require 'spec_helper'

describe Cms, type: :model, dbscope: :example do
  let!(:site) { cms_site }

  describe ".canonical_full_url" do
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
end
