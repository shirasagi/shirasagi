require 'spec_helper'

describe Article::Page, dbscope: :example, tmpdir: true do
  let(:node) { create :article_node_page }

  describe "#attributes" do
    subject(:item) { create :article_page, cur_node: node }
    let(:show_path) { Rails.application.routes.url_helpers.article_page_path(site: subject.site, cid: node, id: subject) }

    it { expect(item.becomes_with_route).not_to be_nil }
    it { expect(item.dirname).to eq node.filename }
    it { expect(item.basename).not_to be_nil }
    it { expect(item.path).not_to be_nil }
    it { expect(item.url).not_to be_nil }
    it { expect(item.full_url).not_to be_nil }
    it { expect(item.parent).to eq node }
    it { expect(item.private_show_path).to eq show_path }
  end

  describe "becomes_with_route" do
    subject(:item) { create :article_page, cur_node: node }
    it do
      page = Cms::Page.find(item.id).becomes_with_route
      expect(page.changed?).to be_falsey
    end
  end

  describe "validation" do
    it "basename" do
      item = build(:article_page_basename_invalid)
      expect(item.invalid?).to be_truthy
    end
  end

  describe "shirasagi-442" do
    subject { create :article_page, cur_node: node, html: "   <p>あ。&rarr;い</p>\r\n   " }
    its(:summary) { is_expected.to eq "あ。→い" }
  end

  describe "#email_for_gravatar" do
    let!(:item) { create :article_page, cur_node: node, gravatar_email: 'gravatar@example.jp' }

    it do
      item.gravatar_image_view_kind = 'disable'
      expect(item.email_for_gravatar).to be_nil
    end

    it do
      item.gravatar_image_view_kind = 'cms_user_email'
      expect(item.email_for_gravatar).to eq item.user.email
    end

    it do
      item.gravatar_image_view_kind = 'special_email'
      expect(item.email_for_gravatar).to eq item.gravatar_email
    end
  end

  describe "#new_clone" do
    context "with simple page" do
      let(:item) { create :article_page, cur_node: node, html: "   <p>あ。&rarr;い</p>\r\n   " }
      subject { item.new_clone }

      it do
        expect(subject.new_record?).to be_truthy
        expect(subject.site_id).to eq item.site_id
        expect(subject.name).to eq item.name
        expect(subject.filename).not_to eq item.filename
        expect(subject.filename).to start_with "#{node.filename}/"
        expect(subject.depth).to eq item.depth
        expect(subject.order).to eq item.order
        expect(subject.state).not_to eq item.state
        expect(subject.state).to eq 'closed'
        expect(subject.group_ids).to eq item.group_ids
        expect(subject.permission_level).to eq item.permission_level
        expect(subject.workflow_user_id).to be_nil
        expect(subject.workflow_state).to be_nil
        expect(subject.workflow_comment).to be_nil
        expect(subject.workflow_approvers).to eq []
        expect(subject.workflow_required_counts).to eq []
        expect(subject.lock_owner_id).to be_nil
        expect(subject.lock_until).to be_nil
      end
    end
  end

  context "with facebook OGP" do
    let(:site0) { cms_site }
    let(:site) { create(:cms_site_subdir, domains: site0.domains, parent_id: site0.id) }
    let(:layout) { create_cms_layout([], cur_site: site) }
    let(:user) { cms_user }
    let(:html) { "   <p>あ。&rarr;い</p>\r\n   " }
    let(:node) { create :article_node_page, cur_site: site }

    before do
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
        create(:article_page, cur_site: site, cur_node: node, cur_user: user, layout_id: layout.id, html: h)
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
        create(:article_page, cur_site: site, cur_node: node, cur_user: user, layout_id: layout.id, html: html)
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
        create(:article_page, cur_site: site, cur_node: node, cur_user: user, layout_id: layout.id, html: h)
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

  context "with twitter card" do
    let(:site)   { cms_site }
    let(:layout) { create_cms_layout }
    let(:user) { cms_user }
    let(:html) { "   <p>あ。&rarr;い</p>\r\n   " }

    before do
      site.twitter_card = 'summary_large_image'
      site.twitter_username = unique_id
      site.save!
    end

    context "with <img>" do
      let(:file) do
        tmp_ss_file(binary: ::File.binread("#{Rails.root}/spec/fixtures/ss/logo.png"), site: site, user: user)
      end
      let(:item) do
        h = html + "<img src=\"#{file.url}\">"
        create(:article_page, cur_site: site, cur_node: node, cur_user: user, layout_id: layout.id, html: h)
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
        create(:article_page, cur_site: site, cur_node: node, cur_user: user, layout_id: layout.id, html: html)
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
        tmp_ss_file(binary: ::File.binread("#{Rails.root}/spec/fixtures/ss/logo.png"), site: site, user: user)
      end
      let(:file1) do
        tmp_ss_file(binary: ::File.binread("#{Rails.root}/spec/fixtures/ss/logo.png"), site: site, user: user)
      end
      let(:item) do
        h = html + "<img src=\"#{file1.url}\"><img src=\"#{file0.url}\">"
        create(:article_page, cur_site: site, cur_node: node, cur_user: user, layout_id: layout.id, html: h)
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
