require 'spec_helper'

describe Article::Page, dbscope: :example do
  let(:node) { create :article_node_page }

  context "with twitter card" do
    let(:site)   { cms_site }
    let(:layout) { create_cms_layout }
    let(:user) { cms_user }
    let(:html) { "   <p>あ。&rarr;い</p>\r\n   " }

    before do
      # to generate keywords and description from html set these attributes
      site.auto_keywords = 'enabled'
      site.auto_description = 'enabled'

      # twitter setting
      site.twitter_card = 'summary_large_image'
      site.twitter_username = unique_id

      site.save!
    end

    context "with <img>" do
      let(:file) do
        tmp_ss_file(binary: File.binread("#{Rails.root}/spec/fixtures/ss/logo.png"), site: site, user: user)
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
        written.scan(/<meta name="twitter:card" .+?>/).first.tap do |meta|
          expect(meta.include?(site.twitter_card)).to be_truthy
        end
        written.scan(/<meta name="twitter:site" .+?>/).first.tap do |meta|
          expect(meta.include?("@#{site.twitter_username}")).to be_truthy
        end
        written.scan(/<meta name="twitter:title" .+?>/).first.tap do |meta|
          expect(meta.include?(item.name)).to be_truthy
        end
        written.scan(/<meta name="twitter:description" .+?>/).first.tap do |meta|
          expect(meta.include?(description)).to be_truthy
        end
        written.scan(/<meta name="twitter:image" .+?>/).tap do |images|
          expect(images.length).to eq 1
          expect(images[0].include?(file.full_url)).to be_truthy
        end
        written.scan(/<meta property="og:url" .+?\/>/).first.tap do |meta|
          expect(meta.include?(item.full_url)).to be_truthy
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
        site.twitter_default_image_url = "https://example.com/#{unique_id}"
        site.save!
      end

      it do
        written.scan(/<meta name="twitter:card" .+?>/).first.tap do |meta|
          expect(meta.include?(site.twitter_card)).to be_truthy
        end
        written.scan(/<meta name="twitter:site" .+?>/).first.tap do |meta|
          expect(meta.include?("@#{site.twitter_username}")).to be_truthy
        end
        written.scan(/<meta name="twitter:title" .+?>/).first.tap do |meta|
          expect(meta.include?(item.name)).to be_truthy
        end
        written.scan(/<meta name="twitter:description" .+?>/).first.tap do |meta|
          expect(meta.include?(description)).to be_truthy
        end
        written.scan(/<meta name="twitter:image" .+?>/).tap do |images|
          expect(images.length).to eq 1
          expect(images[0].include?(site.twitter_default_image_url)).to be_truthy
        end
        written.scan(/<meta property="og:url" .+?\/>/).first.tap do |meta|
          expect(meta.include?(item.full_url)).to be_truthy
        end
      end
    end

    context "with total test" do
      let(:file0) do
        tmp_ss_file(binary: File.binread("#{Rails.root}/spec/fixtures/ss/logo.png"), site: site, user: user)
      end
      let(:file1) do
        tmp_ss_file(binary: File.binread("#{Rails.root}/spec/fixtures/ss/logo.png"), site: site, user: user)
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
        site.twitter_default_image_url = "https://example.com/#{unique_id}"
        site.save!
      end

      it do
        written.scan(/<meta name="twitter:card" .+?>/).first.tap do |meta|
          expect(meta.include?(site.twitter_card)).to be_truthy
        end
        written.scan(/<meta name="twitter:site" .+?>/).first.tap do |meta|
          expect(meta.include?("@#{site.twitter_username}")).to be_truthy
        end
        written.scan(/<meta name="twitter:title" .+?>/).first.tap do |meta|
          expect(meta.include?(item.name)).to be_truthy
        end
        written.scan(/<meta name="twitter:description" .+?>/).first.tap do |meta|
          expect(meta.include?(description)).to be_truthy
        end
        written.scan(/<meta name="twitter:image" .+?>/).tap do |images|
          # should have only one twitter:image
          expect(images.length).to eq 1
          expect(images[0].include?(file1.full_url)).to be_truthy
        end
        written.scan(/<meta property="og:url" .+?\/>/).first.tap do |meta|
          expect(meta.include?(item.full_url)).to be_truthy
        end
      end
    end
  end
end
