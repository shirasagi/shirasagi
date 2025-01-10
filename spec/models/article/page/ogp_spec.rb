require 'spec_helper'

describe Article::Page, dbscope: :example do
  context "with facebook OGP" do
    let(:site0) { cms_site }
    let(:site) { create(:cms_site_subdir, domains: site0.domains, parent_id: site0.id) }
    let(:layout) { create_cms_layout([], cur_site: site) }
    let(:user) { cms_user }
    let(:html) { "   <p>あ。&rarr;い</p>\r\n   " }
    let(:node) { create :article_node_page, cur_site: site }

    before do
      # to generate keywords and description from html set these attributes
      site.auto_keywords = 'enabled'
      site.auto_description = 'enabled'

      # facebook setting
      site.opengraph_type = 'article'
      site.facebook_app_id = unique_id
      site.facebook_page_url = "https://www.facebook.com/pages/#{unique_id}"

      site.save!
    end

    context "with <img>" do
      let(:file) do
        tmp_ss_file(binary: ::File.binread("#{Rails.root}/spec/fixtures/ss/logo.png"), site: site, user: user)
      end
      let(:item) do
        h = html + "<img src=\"#{file.url}\">"
        create(
          :article_page, cur_site: site, cur_node: node, cur_user: user, layout_id: layout.id,
          keywords: nil, description: nil, html: h
        )
      end
      let(:description) do
        ApplicationController.helpers.sanitize(item.html, tags: []).squish.truncate(200)
      end
      let(:written) { File.read(item.path) }

      it do
        written.scan(/<meta property="fb:app_id" .+?\/>/).first.tap do |meta|
          expect(meta.include?(site.facebook_app_id)).to be_truthy
        end
        written.scan(/<meta property="article:author" .+?\/>/).first.tap do |meta|
          expect(meta.include?(site.facebook_page_url)).to be_truthy
        end
        written.scan(/<meta property="article:publisher" .+?\/>/).first.tap do |meta|
          expect(meta.include?(site.facebook_page_url)).to be_truthy
        end
        written.scan(/<meta property="og:type" .+?\/>/).first.tap do |meta|
          expect(meta.include?(site.opengraph_type)).to be_truthy
        end
        written.scan(/<meta property="og:url" .+?\/>/).first.tap do |meta|
          expect(meta.include?(item.full_url)).to be_truthy
        end
        written.scan(/<meta property="og:site_name" .+?\/>/).first.tap do |meta|
          expect(meta.include?(site.name)).to be_truthy
        end
        written.scan(/<meta property="og:title" .+?\/>/).first.tap do |meta|
          expect(meta.include?(item.name)).to be_truthy
        end
        written.scan(/<meta property="og:description" .+?\/>/).first.tap do |meta|
          expect(meta.include?(description)).to be_truthy
        end
        written.scan(/<meta property="og:image" .+?\/>/).first.tap do |meta|
          expect(meta.include?(file.full_url)).to be_truthy
        end
      end
    end

    context "with opengraph_defaul_image_url" do
      let(:item) do
        create(
          :article_page, cur_site: site, cur_node: node, cur_user: user, layout_id: layout.id,
          keywords: nil, description: nil, html: html
        )
      end
      let(:description) do
        ApplicationController.helpers.sanitize(item.html, tags: []).squish.truncate(200)
      end
      let(:written) { File.read(item.path) }

      before do
        site.opengraph_defaul_image_url = "https://example.com/#{unique_id}"
        site.save!
      end

      it do
        written.scan(/<meta property="fb:app_id" .+?\/>/).first.tap do |meta|
          expect(meta.include?(site.facebook_app_id)).to be_truthy
        end
        written.scan(/<meta property="article:author" .+?\/>/).first.tap do |meta|
          expect(meta.include?(site.facebook_page_url)).to be_truthy
        end
        written.scan(/<meta property="article:publisher" .+?\/>/).first.tap do |meta|
          expect(meta.include?(site.facebook_page_url)).to be_truthy
        end
        written.scan(/<meta property="og:type" .+?\/>/).first.tap do |meta|
          expect(meta.include?(site.opengraph_type)).to be_truthy
        end
        written.scan(/<meta property="og:url" .+?\/>/).first.tap do |meta|
          expect(meta.include?(item.full_url)).to be_truthy
        end
        written.scan(/<meta property="og:site_name" .+?\/>/).first.tap do |meta|
          expect(meta.include?(site.name)).to be_truthy
        end
        written.scan(/<meta property="og:title" .+?\/>/).first.tap do |meta|
          expect(meta.include?(item.name)).to be_truthy
        end
        written.scan(/<meta property="og:description" .+?\/>/).first.tap do |meta|
          expect(meta.include?(description)).to be_truthy
        end
        written.scan(/<meta property="og:image" .+?\/>/).first.tap do |meta|
          expect(meta.include?(site.opengraph_defaul_image_url)).to be_truthy
        end
      end
    end

    context "with total test" do
      let(:file0) do
        tmp_ss_file(binary: ::File.binread("#{Rails.root}/spec/fixtures/ss/logo.png"), site: site, user: user)
      end
      let(:file1) do
        tmp_ss_file(binary: ::File.binread("#{Rails.root}/spec/fixtures/ss/logo.png"), site: site, user: user)
      end
      let(:item) do
        h = html + "<img src=\"#{file1.url}\"><img src=\"#{file0.url}\">"
        create(
          :article_page, cur_site: site, cur_node: node, cur_user: user, layout_id: layout.id,
          keywords: nil, description: nil, html: h
        )
      end
      let(:description) do
        ApplicationController.helpers.sanitize(item.html, tags: []).squish.truncate(200)
      end
      let(:written) { File.read(item.path) }

      before do
        site.opengraph_defaul_image_url = "https://example.com/#{unique_id}"
        site.save!
      end

      it do
        written.scan(/<meta property="fb:app_id" .+?\/>/).first.tap do |meta|
          expect(meta.include?(site.facebook_app_id)).to be_truthy
        end
        written.scan(/<meta property="article:author" .+?\/>/).first.tap do |meta|
          expect(meta.include?(site.facebook_page_url)).to be_truthy
        end
        written.scan(/<meta property="article:publisher" .+?\/>/).first.tap do |meta|
          expect(meta.include?(site.facebook_page_url)).to be_truthy
        end
        written.scan(/<meta property="og:type" .+?\/>/).first.tap do |meta|
          expect(meta.include?(site.opengraph_type)).to be_truthy
        end
        written.scan(/<meta property="og:url" .+?\/>/).first.tap do |meta|
          expect(meta.include?(item.full_url)).to be_truthy
        end
        written.scan(/<meta property="og:site_name" .+?\/>/).first.tap do |meta|
          expect(meta.include?(site.name)).to be_truthy
        end
        written.scan(/<meta property="og:title" .+?\/>/).first.tap do |meta|
          expect(meta.include?(item.name)).to be_truthy
        end
        written.scan(/<meta property="og:description" .+?\/>/).first.tap do |meta|
          expect(meta.include?(description)).to be_truthy
        end
        written.scan(/<meta property="og:image" .+?\/>/).tap do |images|
          expect(images.length).to eq 2
          # order is important.
          expect(images[0].include?(file1.full_url)).to be_truthy
          expect(images[1].include?(file0.full_url)).to be_truthy
        end
      end
    end
  end
end
