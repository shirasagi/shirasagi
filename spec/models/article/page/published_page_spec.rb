require 'spec_helper'

describe Article::Page, dbscope: :example do
  let(:node) { create :article_node_page }

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

        expect(::File.exist?(file.public_path)).to be_falsey
        expect(::File.exist?(subject.path)).to be_falsey

        subject.state = "public"
        subject.save!

        expect(::File.exist?(file.public_path)).to be_truthy
        expect(::File.exist?(subject.path)).to be_truthy
      end
    end

    context "when node of page is turned to closed" do
      subject { create :article_page, cur_node: node, state: "public", html: body, file_ids: [ file.id ] }

      it do
        expect(file.site_id).to eq cms_site.id
        expect(file.user_id).to eq cms_user.id
        expect(subject.file_ids).to include(file.id)

        expect(::File.exist?(subject.path)).to be_truthy
        expect(::File.exist?(file.public_path)).to be_truthy

        node.state = "closed"
        node.save!

        SS::PublicFileRemoverJob.bind(site_id: cms_site.id).perform_now

        expect(::File.exist?(subject.path)).to be_falsey
        expect(::File.exist?(file.public_path)).to be_falsey
      end
    end

    context "when node of page is turned to for member" do
      subject { create :article_page, cur_node: node, state: "public", html: body, file_ids: [ file.id ] }

      it do
        expect(file.site_id).to eq cms_site.id
        expect(file.user_id).to eq cms_user.id
        expect(subject.file_ids).to include(file.id)

        expect(::File.exist?(subject.path)).to be_truthy
        expect(::File.exist?(file.public_path)).to be_truthy

        node.for_member_state = "enabled"
        node.save!

        SS::PublicFileRemoverJob.bind(site_id: cms_site.id).perform_now

        expect(::File.exist?(subject.path)).to be_falsey
        expect(::File.exist?(file.public_path)).to be_falsey
      end
    end

    context "when page is published with /fs access restricted" do
      subject { create :article_page, cur_node: node, state: "closed", html: body, file_ids: [ file.id ] }

      it do
        expect(file.site_id).to eq cms_site.id
        expect(file.user_id).to eq cms_user.id
        expect(subject.file_ids).to include(file.id)

        expect(::File.exist?(file.public_path)).to be_falsey
        expect(::File.exist?(subject.path)).to be_falsey

        cms_site.update(file_fs_access_restriction_state: "enabled")

        subject.state = "public"
        subject.save!

        expect(::File.exist?(file.public_path)).to be_falsey
        expect(::File.size(subject.path)).to be > 0
      end
    end
  end
end
