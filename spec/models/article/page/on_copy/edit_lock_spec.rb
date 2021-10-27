require 'spec_helper'

describe Article::Page, dbscope: :example do
  let(:site) { cms_site }
  let(:user) { cms_user }
  let(:node) { create :article_node_page, cur_site: site }
  let!(:item) { create :article_page, cur_site: site, cur_user: user, cur_node: node }
  let(:now) { Time.zone.now.change(usec: 0) }

  describe "on_copy: :clear" do
    context "with Cms::Addon::EditLock" do
      let(:lock_owner_id) { rand(10..20) }
      let(:lock_until) { now + 15.minutes }
      let(:branch_name) { "name-#{unique_id}" }

      before do
        item.set(lock_owner_id: lock_owner_id, lock_until: lock_until.utc)
      end

      context "#new_clone" do
        it do
          item.reload
          expect(item.lock_owner_id).to eq lock_owner_id
          expect(item.lock_until).to eq lock_until

          branch = item.new_clone
          expect(branch.lock_owner_id).to be_blank
          expect(branch.lock_until).to be_blank

          branch.master = item
          branch.save!
          expect(branch.lock_owner_id).to be_blank
          expect(branch.lock_until).to be_blank

          # merge
          branch.class.find(branch.id).tap do |branch|
            branch.name = branch_name
            branch.state = "public"
            expect { branch.save! }.to raise_error Mongoid::Errors::Validations
          end
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
          expect(item.lock_owner_id).to be_blank
          expect(item.lock_until).to be_blank
        end
      end
    end
  end
end
