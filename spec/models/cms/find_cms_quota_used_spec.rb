require 'spec_helper'

describe Cms, type: :model, dbscope: :example do
  let!(:group0) { create :cms_group, name: unique_id }
  let!(:group1) { create :cms_group, name: "#{group0.name}/#{unique_id}" }
  let!(:group2) { create :cms_group, name: "#{group0.name}/#{unique_id}" }
  let!(:site) { create :cms_site_unique, group_ids: [ group0.id ] }
  let!(:other_site) { create :cms_site_unique, group_ids: [ group0.id ] }
  let!(:sub_site) { create :cms_site_unique, domains: site.domain, subdir: "sub", parent: site, group_ids: [ group0.id ] }

  let(:png_file) do
    filename = "#{Rails.root}/spec/fixtures/ss/logo.png"
    basename = ::File.basename(filename)
    SS::File.create_empty!(
      site_id: site.id, cur_user: cms_user, name: basename, filename: basename, content_type: "image/png", model: 'ss/file'
    ) do |file|
      ::FileUtils.cp(filename, file.path)
    end
  end

  def upload_file(upload_site)
    # uploader
    uploader = create(:uploader_node_file, cur_site: upload_site, filename: "img")
    ::FileUtils.mkdir_p(uploader.path)
    ::FileUtils.cp("#{Rails.root}/spec/fixtures/ss/logo.png", "#{uploader.path}/logo.png")

    # cms page
    filename = "#{Rails.root}/spec/fixtures/ss/logo.png"
    basename = ::File.basename(filename)
    file = SS::File.create_empty!(
      site_id: upload_site.id, cur_user: cms_user, name: basename, filename: basename, content_type: "image/png", model: 'ss/file'
    ) { |file| ::FileUtils.cp(filename, file.path) }
    create(:cms_page, filename: "index.html", cur_site: upload_site, file_ids: [ file.id ], group_ids: [ group1.id ])
  end

  after do
    ::FileUtils.rm_rf(site.path) if ::File.exist?(site.path)
    ::FileUtils.rm_rf(other_site.path) if ::File.exist?(other_site.path)
  end

  it { expect(Cms.find_cms_quota_used(Cms::Site.where(id: site.id))).to be >= 700 }

  context "when page-like is created" do
    context "when ads/banner is created" do
      it do
        expect { create(:ads_banner, cur_site: site, file_id: png_file.id, group_ids: [ group1.id ]) }.to \
          change { Cms.find_cms_quota_used(Cms::Site.where(id: site.id)) }.by_at_least(10_000)
      end
    end

    context "when article/page is created" do
      it do
        expectation = expect do
          create(:article_page, cur_site: site, html: unique_id, file_ids: [ png_file.id ], group_ids: [ group1.id ])
        end
        expectation.to change { Cms.find_cms_quota_used(Cms::Site.where(id: site.id)) }.by_at_least(10_000)
      end
    end

    context "when cms/page is created" do
      it do
        expectation = expect do
          create(:cms_page, cur_site: site, html: unique_id, file_ids: [ png_file.id ], group_ids: [ group1.id ])
        end
        expectation.to change { Cms.find_cms_quota_used(Cms::Site.where(id: site.id)) }.by_at_least(10_000)
      end
    end

    context "when key_visual/image is created" do
      it do
        expect { create(:key_visual_image, cur_site: site, group_ids: [ group1.id ]) }.to \
          change { Cms.find_cms_quota_used(Cms::Site.where(id: site.id)) }.by_at_least(10_000)
      end
    end

    context "when other site article/page is created" do
      it do
        expectation = expect do
          create(:article_page, cur_site: other_site, html: unique_id, group_ids: [ group1.id ])
        end
        expectation.to change { Cms.find_cms_quota_used(Cms::Site.where(id: site.id)) }.by(0)
      end
    end
  end

  context "when node-like is created" do
    context "when article/node/page is created" do
      it do
        expect { create(:article_node_page, cur_site: site, group_ids: [ group1.id ]) }.to \
          change { Cms.find_cms_quota_used(Cms::Site.where(id: site.id)) }.by_at_least(500)
      end
    end

    context "when category/node/node is created" do
      it do
        expect { create(:category_node_node, cur_site: site, group_ids: [ group1.id ]) }.to \
          change { Cms.find_cms_quota_used(Cms::Site.where(id: site.id)) }.by_at_least(500)
      end
    end

    context "when cms/node/node is created" do
      it do
        expect { create(:cms_node_node, cur_site: site, group_ids: [ group1.id ]) }.to \
          change { Cms.find_cms_quota_used(Cms::Site.where(id: site.id)) }.by_at_least(500)
      end
    end

    context "when facility/node/page is created" do
      it do
        expect { create(:facility_node_page, cur_site: site, group_ids: [ group1.id ]) }.to \
          change { Cms.find_cms_quota_used(Cms::Site.where(id: site.id)) }.by_at_least(400)
      end
    end
  end

  context "when part-like is created" do
    context "when cms/part/free is created" do
      it do
        expect { create(:cms_part_free, cur_site: site, html: unique_id, group_ids: [ group1.id ]) }.to \
          change { Cms.find_cms_quota_used(Cms::Site.where(id: site.id)) }.by_at_least(300)
      end
    end

    context "when cms/part/node is created" do
      it do
        expect { create(:cms_part_node, cur_site: site, loop_html: unique_id, group_ids: [ group1.id ]) }.to \
          change { Cms.find_cms_quota_used(Cms::Site.where(id: site.id)) }.by_at_least(300)
      end
    end

    context "when cms/part/page is created" do
      it do
        expect { create(:cms_part_node, cur_site: site, loop_html: unique_id, group_ids: [ group1.id ]) }.to \
          change { Cms.find_cms_quota_used(Cms::Site.where(id: site.id)) }.by_at_least(300)
      end
    end
  end

  context "when layout-like is created" do
    context "when cms/layout is created" do
      it do
        expect { create(:cms_layout, cur_site: site, html: unique_id, group_ids: [ group1.id ]) }.to \
          change { Cms.find_cms_quota_used(Cms::Site.where(id: site.id)) }.by_at_least(300)
      end
    end

    context "when cms/body_layout is created" do
      it do
        expect { create(:cms_body_layout, cur_site: site, html: unique_id, group_ids: [ group1.id ]) }.to \
          change { Cms.find_cms_quota_used(Cms::Site.where(id: site.id)) }.by_at_least(300)
      end
    end

    context "when member/blog_layout is created" do
      it do
        expect { create(:member_blog_layout, cur_site: site, html: unique_id, group_ids: [ group1.id ]) }.to \
          change { Cms.find_cms_quota_used(Cms::Site.where(id: site.id)) }.by_at_least(300)
      end
    end
  end

  context "when cms/group is created" do
    context "when child group is created" do
      it do
        expect { create(:cms_group, name: "#{group1.name}/#{unique_id}") }.to \
          change { Cms.find_cms_quota_used(Cms::Site.where(id: site.id)) }.by_at_least(50)
      end
    end

    context "when other organization group is created" do
      it do
        expect { create(:cms_group, name: unique_id) }.to \
          change { Cms.find_cms_quota_used(Cms::Site.where(id: site.id)) }.by(0)
      end
    end

    context "when none-active group is created" do
      it do
        expect { create(:cms_group, name: "#{group1.name}/#{unique_id}", expiration_date: Time.zone.now - 1.minute) }.to \
          change { Cms.find_cms_quota_used(Cms::Site.where(id: site.id)) }.by_at_least(50)
      end
    end
  end

  context "when cms/user is created" do
    context "with usual case" do
      it do
        expect { create(:cms_user, uid: unique_id, email: "#{unique_id}@example.jp", group_ids: [ group1.id ]) }.to \
          change { Cms.find_cms_quota_used(Cms::Site.where(id: site.id)) }.by_at_least(400)
      end
    end

    context "when other organization user is created" do
      it do
        expectation = expect do
          other_organization = create(:cms_group, name: unique_id)
          create(:cms_user, uid: unique_id, email: "#{unique_id}@example.jp", group_ids: [ other_organization.id ])
        end
        expectation.to change { Cms.find_cms_quota_used(Cms::Site.where(id: site.id)) }.by(0)
      end
    end

    context "when none-active user is created" do
      it do
        expectation = expect do
          time = Time.zone.now - 1.minute
          create(
            :cms_user, uid: unique_id, email: "#{unique_id}@example.jp", account_expiration_date: time, group_ids: [ group1.id ]
          )
        end
        expectation.to change { Cms.find_cms_quota_used(Cms::Site.where(id: site.id)) }.by_at_least(400)
      end
    end
  end

  context "when cms/role is created" do
    it do
      expect { create(:cms_role_admin, cur_site: site, name: unique_id) }.to \
        change { Cms.find_cms_quota_used(Cms::Site.where(id: site.id)) }.by_at_least(10_000)
    end
  end

  context "when cms/member is created" do
    it do
      expect { create(:cms_member, cur_site: site) }.to \
        change { Cms.find_cms_quota_used(Cms::Site.where(id: site.id)) }.by_at_least(200)
    end
  end

  context "when chorg/revision is created" do
    it do
      expectation = expect do
        revision = create(:revision, cur_site: site)
        create(:add_changeset, revision_id: revision.id)
        create(:move_changeset, revision_id: revision.id, source: group2)
        create(:unify_changeset, revision_id: revision.id, sources: [group1, group2])
        create(:division_changeset, revision_id: revision.id, source: group1, destination: [group2])
        create(:delete_changeset, revision_id: revision.id, source: group1)
      end
      expectation.to change { Cms.find_cms_quota_used(Cms::Site.where(id: site.id)) }.by_at_least(100)
    end
  end

  context "when workflow/route is created" do
    it do
      expect { create(:workflow_route, group_ids: [ group2.id ]) }.to \
        change { Cms.find_cms_quota_used(Cms::Site.where(id: site.id)) }.by_at_least(200)
    end
  end

  context "when kana/dictionary is created" do
    it do
      expect { create(:kana_dictionary, cur_site: site) }.to \
        change { Cms.find_cms_quota_used(Cms::Site.where(id: site.id)) }.by_at_least(150)
    end
  end

  context "when uploader/file is created" do
    context "when file uploaded" do
      it "used of site" do
        expect { upload_file(site) }.to \
          change { Cms.find_cms_quota_used(Cms::Site.where(id: site.id)) }.by_at_least(10_000)
      end

      it "used of other site" do
        expect { upload_file(site) }.to \
          change { Cms.find_cms_quota_used(Cms::Site.where(id: other_site.id)) }.by(0)
      end

      it "used of sub site" do
        expect { upload_file(site) }.to \
          change { Cms.find_cms_quota_used(Cms::Site.where(id: sub_site.id)) }.by(0)
      end
    end

    context "when other site file uploaded" do
      it "used of site" do
        expect { upload_file(other_site) }.to \
          change { Cms.find_cms_quota_used(Cms::Site.where(id: site.id)) }.by(0)
      end

      it "used of other site" do
        expect { upload_file(other_site) }.to \
          change { Cms.find_cms_quota_used(Cms::Site.where(id: other_site.id)) }.by_at_least(10_000)
      end

      it "used of sub site" do
        expect { upload_file(other_site) }.to \
          change { Cms.find_cms_quota_used(Cms::Site.where(id: sub_site.id)) }.by(0)
      end
    end

    context "when sub site file uploaded" do
      it "used of site" do
        expect { upload_file(sub_site) }.to \
          change { Cms.find_cms_quota_used(Cms::Site.where(id: site.id)) }.by(0)
      end

      it "used of other site" do
        expect { upload_file(sub_site) }.to \
          change { Cms.find_cms_quota_used(Cms::Site.where(id: other_site.id)) }.by(0)
      end

      it "used of sub site" do
        expect { upload_file(sub_site) }.to \
          change { Cms.find_cms_quota_used(Cms::Site.where(id: sub_site.id)) }.by_at_least(10_000)
      end
    end
  end
end
