require 'spec_helper'

describe Article::Page, dbscope: :example do
  let(:site) { cms_site }
  let(:user) { cms_user }
  let(:node) { create :article_node_page, cur_site: site }
  let!(:item) { create :article_page, cur_site: site, cur_user: user, cur_node: node }
  let(:now) { Time.zone.now.change(usec: 0) }
  let(:file_path) { "#{Rails.root}/spec/fixtures/ss/logo.png" }

  describe "on_copy: :clear" do
    context "with Cms::Addon::TwitterPoster" do
      let(:twitter_auto_post) { %w(expired active).sample }
      let(:twitter_post_format) { I18n.t("cms.options.twitter_post_format").keys.sample.to_s }
      let(:twitter_edit_auto_post) { %w(disabled enabled).sample.to_s }
      let(:twitter_posted) { [ { "twitter_post_id" => unique_id, "twitter_user_id" => rand(1..10), "posted_at" => now.utc } ] }
      let(:twitter_post_error) { unique_id }
      let(:branch_name) { "name-#{unique_id}" }
      let(:branch_twitter_auto_post) { %w(expired active).sample }
      let(:branch_twitter_post_format) { I18n.t("cms.options.twitter_post_format").keys.sample.to_s }
      let(:branch_twitter_edit_auto_post) { %w(disabled enabled).sample.to_s }

      before do
        file = tmp_ss_file(site: site, user: user, contents: file_path)

        item.update!(
          thumb_id: file.id,
          twitter_auto_post: twitter_auto_post, twitter_post_format: twitter_post_format,
          twitter_edit_auto_post: twitter_edit_auto_post,
          twitter_posted: twitter_posted, twitter_post_error: twitter_post_error
        )
      end

      context "#new_clone" do
        it do
          item.reload
          expect(item.twitter_auto_post).to eq twitter_auto_post
          expect(item.twitter_post_format).to eq twitter_post_format
          expect(item.twitter_edit_auto_post).to eq twitter_edit_auto_post
          expect(item.twitter_posted).to eq twitter_posted
          expect(item.twitter_post_error).to eq twitter_post_error

          branch = item.new_clone
          expect(branch.twitter_auto_post).to eq "expired"
          expect(branch.twitter_post_format).to eq twitter_post_format
          expect(branch.twitter_edit_auto_post).to eq "disabled"
          expect(branch.twitter_posted).to be_blank
          expect(branch.twitter_post_error).to be_blank

          branch.master = item
          branch.save!
          expect(branch.twitter_auto_post).to eq "expired"
          expect(branch.twitter_post_format).to eq twitter_post_format
          expect(branch.twitter_edit_auto_post).to eq "disabled"
          expect(branch.twitter_posted).to be_blank
          expect(branch.twitter_post_error).to be_blank

          # merge
          branch.class.find(branch.id).tap do |branch|
            branch.name = branch_name
            branch.state = "public"
            branch.twitter_auto_post = branch_twitter_auto_post
            branch.twitter_post_format = branch_twitter_post_format
            branch.twitter_edit_auto_post = branch_twitter_edit_auto_post
            branch.save!
            branch.destroy
          end

          item.reload
          expect(item.name).to eq branch_name
          expect(item.twitter_auto_post).to eq branch_twitter_auto_post
          expect(item.twitter_post_format).to eq branch_twitter_post_format
          expect(item.twitter_edit_auto_post).to eq branch_twitter_edit_auto_post
          expect(item.twitter_posted).to eq twitter_posted
          expect(item.twitter_post_error).to eq twitter_post_error
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
          expect(copy.twitter_auto_post).to eq "expired"
          expect(copy.twitter_post_format).to eq twitter_post_format
          expect(copy.twitter_edit_auto_post).to eq "disabled"
          expect(copy.twitter_posted).to be_blank
          expect(copy.twitter_post_error).to be_blank
        end
      end
    end
  end
end
