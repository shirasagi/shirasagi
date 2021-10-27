require 'spec_helper'

describe Article::Page, dbscope: :example do
  let(:site) { cms_site }
  let(:user) { cms_user }
  let(:node) { create :article_node_page, cur_site: site }
  let!(:item) { create :article_page, cur_site: site, cur_user: user, cur_node: node }
  let(:now) { Time.zone.now.change(usec: 0) }
  let(:file_path) { "#{Rails.root}/spec/fixtures/ss/logo.png" }

  describe "on_copy: :clear" do
    context "with Cms::Addon::LinePoster" do
      let(:line_auto_post) { %w(expired active).sample }
      let(:line_edit_auto_post) { %w(disabled enabled).sample }
      let(:line_posted) { [ now.utc ] }
      let(:line_post_error) { unique_id }
      let(:line_text_message) { unique_id }
      let(:line_post_format) { %w(thumb_carousel body_carousel message_only_carousel).sample }
      let(:branch_name) { "name-#{unique_id}" }
      let(:branch_line_auto_post) { %w(expired active).sample }
      let(:branch_line_edit_auto_post) { %w(disabled enabled).sample }
      let(:branch_line_text_message) { unique_id }
      let(:branch_line_post_format) { %w(thumb_carousel body_carousel message_only_carousel).sample }

      before do
        file = tmp_ss_file(site: site, user: user, contents: file_path)

        item.update!(
          thumb_id: file.id,
          line_auto_post: line_auto_post, line_edit_auto_post: line_edit_auto_post,
          line_posted: line_posted, line_post_error: line_post_error,
          line_text_message: line_text_message, line_post_format: line_post_format
        )
      end

      context "#new_clone" do
        it do
          item.reload
          expect(item.line_auto_post).to eq line_auto_post
          expect(item.line_edit_auto_post).to eq line_edit_auto_post
          expect(item.line_posted).to eq line_posted
          expect(item.line_post_error).to eq line_post_error
          expect(item.line_text_message).to eq line_text_message
          expect(item.line_post_format).to eq line_post_format

          branch = item.new_clone
          expect(branch.line_auto_post).to eq "expired"
          expect(branch.line_edit_auto_post).to eq "disabled"
          expect(branch.line_posted).to be_blank
          expect(branch.line_post_error).to be_blank
          expect(branch.line_text_message).to eq line_text_message
          expect(branch.line_post_format).to eq line_post_format

          branch.master = item
          branch.save!
          expect(branch.line_auto_post).to eq "expired"
          expect(branch.line_edit_auto_post).to eq "disabled"
          expect(branch.line_posted).to be_blank
          expect(branch.line_post_error).to be_blank
          expect(branch.line_text_message).to eq line_text_message
          expect(branch.line_post_format).to eq line_post_format

          # merge
          branch.class.find(branch.id).tap do |branch|
            branch.name = branch_name
            branch.state = "public"
            branch.line_auto_post = branch_line_auto_post
            branch.line_edit_auto_post = branch_line_edit_auto_post
            branch.line_text_message = branch_line_text_message
            branch.line_post_format = branch_line_post_format
            branch.save!
            branch.destroy
          end

          item.reload
          expect(item.name).to eq branch_name
          expect(item.line_auto_post).to eq branch_line_auto_post
          expect(item.line_edit_auto_post).to eq branch_line_edit_auto_post
          expect(item.line_posted).to eq line_posted
          expect(item.line_post_error).to eq line_post_error
          expect(item.line_text_message).to eq branch_line_text_message
          expect(item.line_post_format).to eq branch_line_post_format
        end
      end

      context "with sys/site_copy_job" do
        let!(:task) { Sys::SiteCopyTask.new }
        let(:target_host_name) { unique_id }
        let(:target_host_host) { unique_id }
        let(:target_host_domain) { "#{unique_id}.example.jp" }

        before do
          task.target_host_name = target_host_name
          task.target_host_host = target_host_host
          task.target_host_domains = [ target_host_domain ]
          task.source_site_id = site.id
          task.copy_contents = "pages"
          task.save!
        end

        it do
          expect { Sys::SiteCopyJob.perform_now }.to output(include(item.filename)).to_stdout

          expect(Job::Log.count).to eq 1
          Job::Log.first.tap do |log|
            expect(log.logs).to include(/INFO -- : .* Started Job/)
            expect(log.logs).to include(/INFO -- : .* Completed Job/)
          end

          target_site = Cms::Site.find_by(name: target_host_name)
          expect(Article::Page.site(target_site).count).to eq 1
          copy = Article::Page.site(target_site).first
          expect(copy.name).to eq item.name
          expect(copy.line_auto_post).to eq "expired"
          expect(copy.line_edit_auto_post).to eq "disabled"
          expect(copy.line_posted).to be_blank
          expect(copy.line_post_error).to be_blank
          expect(copy.line_text_message).to eq line_text_message
          expect(copy.line_post_format).to eq line_post_format
        end
      end
    end
  end
end
