require 'spec_helper'

describe Article::Page, dbscope: :example do
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
    let(:site_limit0) { create :cms_site_unique, max_name_length: 0 }
    let(:site_limit80) { create :cms_site_unique, max_name_length: 80 }

    it "basename" do
      item = build(:article_page_basename_invalid)
      expect(item.invalid?).to be_truthy
    end

    it "name with limit 0" do
      item = build(:article_page_10_characters_name, cur_site: site_limit0)
      expect(item.valid?).to be_truthy

      item = build(:article_page_100_characters_name, cur_site: site_limit0)
      expect(item.valid?).to be_truthy

      item = build(:article_page_1000_characters_name, cur_site: site_limit0)
      expect(item.valid?).to be_truthy
    end

    it "name with limit 80" do
      item = build(:article_page_10_characters_name, cur_site: site_limit80)
      expect(item.valid?).to be_truthy

      item = build(:article_page_100_characters_name, cur_site: site_limit80)
      expect(item.valid?).to be_falsey

      item = build(:article_page_1000_characters_name, cur_site: site_limit80)
      expect(item.valid?).to be_falsey
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

  describe "what published page is" do
    let(:path) { "#{Rails.root}/spec/fixtures/ss/logo.png" }
    let(:file) do
      SS::TempFile.create_empty!(
        cur_user: cms_user, site_id: cms_site.id, filename: "logo.png", content_type: 'image/png'
      ) do |file|
        ::FileUtils.cp(path, file.path)
      end
    end
    let(:body) { Array.new(rand(5..10)) { unique_id }.join("\n") + file.url }

    context "when closed page is published" do
      subject { create :article_page, cur_node: node, state: "closed", html: body, file_ids: [ file.id ] }

      it do
        expect(file.site_id).to eq cms_site.id
        expect(file.user_id).to eq cms_user.id
        expect(subject.file_ids).to include(file.id)

        expect(::File.exists?(file.public_path)).to be_falsey
        expect(::File.exists?(subject.path)).to be_falsey

        subject.state = "public"
        subject.save!

        expect(::File.exists?(file.public_path)).to be_truthy
        expect(::File.exists?(subject.path)).to be_truthy
      end
    end

    context "when node of page is turned to closed" do
      subject { create :article_page, cur_node: node, state: "public", html: body, file_ids: [ file.id ] }

      it do
        expect(file.site_id).to eq cms_site.id
        expect(file.user_id).to eq cms_user.id
        expect(subject.file_ids).to include(file.id)

        expect(::File.exists?(subject.path)).to be_truthy
        expect(::File.exists?(file.public_path)).to be_truthy

        node.state = "closed"
        node.save!

        SS::PublicFileRemoverJob.bind(site_id: cms_site.id).perform_now

        expect(::File.exists?(subject.path)).to be_falsey
        expect(::File.exists?(file.public_path)).to be_falsey
      end
    end

    context "when node of page is turned to for member" do
      subject { create :article_page, cur_node: node, state: "public", html: body, file_ids: [ file.id ] }

      it do
        expect(file.site_id).to eq cms_site.id
        expect(file.user_id).to eq cms_user.id
        expect(subject.file_ids).to include(file.id)

        expect(::File.exists?(subject.path)).to be_truthy
        expect(::File.exists?(file.public_path)).to be_truthy

        node.for_member_state = "enabled"
        node.save!

        SS::PublicFileRemoverJob.bind(site_id: cms_site.id).perform_now

        expect(::File.exists?(subject.path)).to be_falsey
        expect(::File.exists?(file.public_path)).to be_falsey
      end
    end
  end

  describe "what article/page exports to liquid" do
    let(:assigns) { { "parts" => SS::LiquidPartDrop.get(cms_site) } }
    let(:registers) { { cur_site: cms_site, cur_node: node, cur_path: page.url } }
    subject { page.to_liquid }

    before do
      subject.context = ::Liquid::Context.new(assigns, {}, registers, true)
    end

    context "without form" do
      context "with Cms::Content" do
        let!(:released) { Time.zone.now.change(min: rand(0..59)) }
        let!(:page) { create :article_page, cur_node: node, index_name: unique_id, released: released }

        it do
          # Cms::Content
          expect(subject.id).to eq page.id
          expect(subject.name).to eq page.name
          expect(subject.index_name).to eq page.index_name
          expect(subject.url).to eq page.url
          expect(subject.full_url).to eq page.full_url
          expect(subject.basename).to eq page.basename
          expect(subject.filename).to eq page.filename
          expect(subject.order).to eq page.order
          expect(subject.date).to eq page.date
          expect(subject.released).to eq page.released
          expect(subject.updated).to eq page.updated
          expect(subject.created).to eq page.created
          expect(subject.parent.id).to eq node.id
          expect(subject.css_class).to eq page.basename.sub(".html", "").dasherize
          expect(subject.new?).to be_truthy
          expect(subject.current?).to be_truthy
        end
      end

      context "with Cms::Model::Page" do
        let!(:cate1) { create :category_node_page, name: "z", order: 10 }
        let!(:cate2) { create :category_node_page, name: "y", order: 20 }
        let!(:page) { create :article_page, cur_node: node, category_ids: [ cate1.id, cate2.id ] }

        it do
          # Cms::Model::Page
          expect(subject.categories.length).to eq 2
          expect(subject.categories.map(&:id)).to include(cate1.id, cate2.id)
        end
      end

      context "with Cms::Addon::Meta" do
        let(:summary) { Array.new(2) { "<p>#{unique_id}</p>" }.join("\n") }
        let(:description) { Array.new(2) { unique_id }.join("\n") }
        let!(:page) do
          create :article_page, cur_node: node, summary_html: summary, description: description
        end

        it do
          # Cms::Addon::Meta
          expect(subject.summary).to eq page.summary_html
          expect(subject.description).to eq description
        end
      end

      context "with Gravatar::Addon::Gravatar" do
        let!(:page) do
          create(
            :article_page, cur_node: node, gravatar_image_view_kind: "special_email",
            gravatar_email: "#{unique_id}@example.jp", gravatar_screen_name: unique_id
          )
        end

        it do
          # Gravatar::Addon::Gravatar
          expect(subject.gravatar_disabled).to eq SS.config.gravatar.disable
          expect(subject.gravatar_enabled).to eq !SS.config.gravatar.disable
          expect(subject.gravatar_image_size).to eq SS.config.gravatar.image_size
          expect(subject.gravatar_default_image_path).to eq SS.config.gravatar.default_image_path
          expect(subject.gravatar_image_view_kind).to eq page.gravatar_image_view_kind
          expect(subject.gravatar_email).to eq page.gravatar_email
          expect(subject.gravatar_screen_name).to eq page.gravatar_screen_name
        end
      end

      context "with Cms::Addon::Thumb" do
        let!(:thumb) do
          SS::File.create_empty!(
            cur_user: cms_user, site_id: cms_site.id, model: "article/page", filename: "logo.png", content_type: 'image/png'
          ) do |file|
            ::FileUtils.cp("#{Rails.root}/spec/fixtures/ss/logo.png", file.path)
          end
        end
        let!(:page) { create :article_page, cur_node: node, thumb: thumb }

        it do
          # Cms::Addon::Thumb
          expect(subject.thumb.name).to eq thumb.name
        end
      end

      context "with Cms::Addon::Body" do
        let(:html) { Array.new(2) { "<p>#{unique_id}</p>" }.join("\n") }
        let!(:page) { create :article_page, cur_node: node, html: html }

        it do
          # Cms::Addon::Body
          expect(subject.html).to eq html
        end
      end

      context "with Cms::Addon::Form::Page" do
        let!(:page) { create :article_page, cur_node: node }

        it do
          # Cms::Addon::Form::Page
          expect(subject.values).to be_blank
        end
      end

      context "with Event::Addon::Date" do
        let!(:term1) do
          term1_start_at = Time.zone.now.beginning_of_day
          Array.new(3) { |i| term1_start_at + i.days }
        end
        let!(:term2) do
          term2_start_at = Time.zone.now.beginning_of_day + 1.month
          Array.new(5) { |i| term2_start_at + i.days }
        end
        let!(:event_deadline) { Time.zone.now.change(min: rand(0..59)) }
        let!(:page) do
          create(
            :article_page, cur_node: node, event_name: unique_id, event_dates: term1 + term2, event_deadline: event_deadline
          )
        end

        it do
          # Event::Addon::Date
          expect(subject.event_name).to eq page.event_name
          expect(subject.event_dates.length).to eq 2
          expect(subject.event_dates[0].length).to eq term1.length
          expect(subject.event_dates[0][0]).to eq term1[0]
          expect(subject.event_dates[1].length).to eq term2.length
          expect(subject.event_dates[1][0]).to eq term2[0]
          expect(subject.event_deadline).to eq page.event_deadline
        end
      end

      context "with Map::Addon::Page" do
        let!(:map_point1) { { "name" => unique_id, "loc" => [ rand(30..40), rand(135..145) ], "text" => unique_id } }
        let!(:map_point2) { { "name" => unique_id, "loc" => [ rand(30..40), rand(135..145) ], "text" => unique_id } }
        let!(:map_points) { [ map_point1, map_point2 ] }
        let!(:page) { create :article_page, cur_node: node, map_points: map_points, map_zoom_level: rand(10..15) }

        it do
          # Map::Addon::Page
          expect(subject.map_points.length).to eq 2
          expect(subject.map_points[0]["name"]).to eq map_point1["name"]
          expect(subject.map_points[0]["loc"]).to eq map_point1["loc"]
          expect(subject.map_points[0]["text"]).to eq map_point1["text"]
          expect(subject.map_points[1]["name"]).to eq map_point2["name"]
          expect(subject.map_points[1]["loc"]).to eq map_point2["loc"]
          expect(subject.map_points[1]["text"]).to eq map_point2["text"]
          expect(subject.map_zoom_level).to eq page.map_zoom_level
        end
      end

      context "with Cms::Addon::RelatedPage" do
        let!(:related1) { create :article_page, cur_node: node, released: Time.zone.now.change(min: 1) }
        let!(:related2) { create :article_page, cur_node: node, released: Time.zone.now.change(min: 2) }
        let!(:page) { create :article_page, cur_node: node, related_page_ids: [ related1.id, related2.id ] }

        it do
          # Cms::Addon::RelatedPage
          expect(subject.related_pages.length).to eq 2
          expect(subject.related_pages[0].id).to eq related2.id
          expect(subject.related_pages[1].id).to eq related1.id
        end
      end

      context "with Contact::Addon::Page" do
        let!(:group1) { create :cms_group, name: "#{cms_group.name}/#{unique_id}" }
        let!(:page) do
          create(
            :article_page, cur_node: node, contact_state: "show", contact_charge: unique_id,
            contact_tel: "0000", contact_fax: "9999", contact_email: "#{unique_id}@example.jp",
            contact_link_url: "https://#{unique_id}.example.jp/", contact_link_name: unique_id,
            contact_group: group1
          )
        end

        it do
          # Contact::Addon::Page
          expect(subject.contact_state).to eq page.contact_state
          expect(subject.contact_charge).to eq page.contact_charge
          expect(subject.contact_tel).to eq page.contact_tel
          expect(subject.contact_fax).to eq page.contact_fax
          expect(subject.contact_email).to eq page.contact_email
          expect(subject.contact_link_url).to eq page.contact_link_url
          expect(subject.contact_link_name).to eq page.contact_link_name
          expect(subject.contact_group.name).to eq page.contact_group.name
        end
      end

      context "with Cms::Addon::Tag" do
        let!(:page) { create :article_page, cur_node: node, tags: Array.new(2) { unique_id } }

        it do
          # Cms::Addon::Tag
          expect(subject.tags.length).to eq page.tags.length
          expect(subject.tags).to eq page.tags
        end
      end

      context "with Cms::Addon::GroupPermission" do
        let!(:group1) { create :cms_group, name: "#{cms_group.name}/#{unique_id}", order: 1 }
        let!(:group2) { create :cms_group, name: "#{cms_group.name}/#{unique_id}", order: 2 }
        let!(:page) { create :article_page, cur_node: node, group_ids: [ group1.id, group2.id ] }

        it do
          # Cms::Addon::GroupPermission
          expect(subject.groups.length).to eq 2
          expect(subject.groups[0].name).to eq group1.name
          expect(subject.groups[1].name).to eq group2.name
        end
      end
    end

    context "with form" do
      let!(:form) { create(:cms_form, cur_site: cms_site, state: 'public', sub_type: 'static') }
      let!(:column1) { create(:cms_column_text_field, cur_form: form, order: 1, input_type: 'text') }
      let!(:page) do
        create(
          :article_page, cur_node: node, form: form,
          column_values: [
            column1.value_type.new(column: column1, value: unique_id * 2)
          ]
        )
      end

      before do
        node.st_form_ids = [ form.id ]
        node.save!

        form.html = "<p>{{ values['#{column1.name}'] }}</p>"
        form.save!
      end

      context "with Cms::Addon::Body" do
        it do
          # Cms::Addon::Body
          expect(subject.html).to eq "<p>#{page.column_values[0].value}</p>"
        end
      end

      context "with Cms::Addon::Form::Page" do
        it do
          # Cms::Addon::Form::Page
          expect(subject.values.length).to eq 1
          expect(subject.values[0].value).to eq page.column_values[0].value
        end
      end
    end
  end

  context "when release plan is given" do
    let(:body) { Array.new(rand(2..5)) { unique_id }.join("\n") }
    let(:current) { Time.zone.now.beginning_of_minute }
    let(:release_date) { current + 1.day }
    let(:close_date) { release_date + 1.day }
    subject do
      create(
        :article_page, cur_node: node, state: "public", released: current, html: body,
        release_date: release_date, close_date: close_date
      )
    end

    describe "release plan lifecycle" do
      it do
        # before release date, state is "ready" even though page is created as "public"
        expect(subject.state).to eq "ready"
        expect(subject.released).to eq current
        expect(subject.release_date).to eq release_date
        expect(subject.close_date).to eq close_date

        # just before release date
        Timecop.freeze(release_date - 1.second) do
          job = Cms::Page::ReleaseJob.bind(site_id: node.site_id, node_id: node.id)
          expect { job.perform_now }.to output.to_stdout
        end

        subject.reload
        expect(subject.state).to eq "ready"
        expect(subject.released).to eq current
        expect(subject.release_date).to eq release_date
        expect(subject.close_date).to eq close_date

        # at release date
        Timecop.freeze(release_date) do
          job = Cms::Page::ReleaseJob.bind(site_id: node.site_id, node_id: node.id)
          expect { job.perform_now }.to output(include(subject.full_url + "\n")).to_stdout
        end

        subject.reload
        expect(subject.state).to eq "public"
        expect(subject.released).to eq current
        expect(subject.release_date).to be_nil
        expect(subject.close_date).to eq close_date

        # just before close date
        Timecop.freeze(close_date - 1.second) do
          job = Cms::Page::ReleaseJob.bind(site_id: node.site_id, node_id: node.id)
          expect { job.perform_now }.to output.to_stdout
        end

        subject.reload
        expect(subject.state).to eq "public"
        expect(subject.released).to eq current
        expect(subject.release_date).to be_nil
        expect(subject.close_date).to eq close_date

        # at close date
        Timecop.freeze(close_date) do
          job = Cms::Page::ReleaseJob.bind(site_id: node.site_id, node_id: node.id)
          expect { job.perform_now }.to output(include(subject.full_url + "\n")).to_stdout
        end

        subject.reload
        expect(subject.state).to eq "closed"
        expect(subject.released).to eq current
        # finally, both release_date and close_data are nil, only release_date leaves
        expect(subject.release_date).to be_nil
        expect(subject.close_date).to be_nil
      end
    end

    describe ".and_public" do
      it do
        # ensure that subject is created
        subject.reload

        # without specific date to and_public
        expect(described_class.and_public.count).to eq 0
        # just before release date
        expect(described_class.and_public(release_date - 1.second).count).to eq 0
        # at release date
        expect(described_class.and_public(release_date).count).to eq 1
        # just before close date
        expect(described_class.and_public(close_date - 1.second).count).to eq 1
        # at close date
        expect(described_class.and_public(close_date).count).to eq 0

        # at release date
        Timecop.freeze(release_date) do
          job = Cms::Page::ReleaseJob.bind(site_id: node.site_id, node_id: node.id)
          expect { job.perform_now }.to output(include(subject.full_url + "\n")).to_stdout

          subject.reload

          # without specific date to and_public
          expect(described_class.and_public.count).to eq 1
          # at release date
          expect(described_class.and_public(release_date).count).to eq 1
          # just before close date
          expect(described_class.and_public(close_date - 1.second).count).to eq 1
          # at close date
          expect(described_class.and_public(close_date).count).to eq 0

          # PAST is unknown because release date is set to nil, so that page is detected as public
          expect(described_class.and_public(release_date - 1.second).count).to eq 1
        end

        # at close date
        Timecop.freeze(close_date) do
          job = Cms::Page::ReleaseJob.bind(site_id: node.site_id, node_id: node.id)
          expect { job.perform_now }.to output(include(subject.full_url + "\n")).to_stdout

          subject.reload

          # without specific date to and_public
          expect(described_class.and_public.count).to eq 0
          # at close date
          expect(described_class.and_public(close_date).count).to eq 0

          # PAST is unknown because release date is set to nil, so that page is detected as closed
          expect(described_class.and_public(release_date - 1.second).count).to eq 0
          expect(described_class.and_public(release_date).count).to eq 0
          expect(described_class.and_public(close_date - 1.second).count).to eq 0
        end
      end
    end

    describe "consistency of `#public?` and `.and_public`" do
      it do
        # just before release date
        Timecop.freeze(release_date - 1.second) do
          subject.reload
          expect(described_class.and_public.count).to eq 0
          expect(subject.public?).to be_falsey
        end

        # at release date
        Timecop.freeze(release_date) do
          # before page is released
          subject.reload
          expect(described_class.and_public.count).to eq 0
          expect(subject.public?).to be_falsey

          job = Cms::Page::ReleaseJob.bind(site_id: node.site_id, node_id: node.id)
          expect { job.perform_now }.to output(include(subject.full_url + "\n")).to_stdout

          # after page was released
          subject.reload
          expect(described_class.and_public.count).to eq 1
          expect(described_class.and_public.first).to eq subject
          expect(subject.public?).to be_truthy
        end

        # at close date
        Timecop.freeze(close_date) do
          # before page is closed
          subject.reload
          expect(described_class.and_public.count).to eq 1
          expect(described_class.and_public.first).to eq subject
          expect(subject.public?).to be_truthy

          job = Cms::Page::ReleaseJob.bind(site_id: node.site_id, node_id: node.id)
          expect { job.perform_now }.to output(include(subject.full_url + "\n")).to_stdout

          # after page was closed
          subject.reload
          expect(described_class.and_public.count).to eq 0
          expect(subject.public?).to be_falsey
        end
      end
    end
  end
end
