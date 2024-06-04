require 'spec_helper'

describe "fs_files", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:user) { cms_user }
  let(:file) do
    SS::Sequence.create(id: 'ss_files_id', value: rand(1_000..1_999))
    tmp_ss_file(contents: filename, site_id: site.id, cur_user: user)
  end

  context "[logo.png]" do
    let(:filename) { "#{Rails.root}/spec/fixtures/ss/logo.png" }

    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    context "file without owner_item" do
      context "without auth" do
        it "via url" do
          visit file.url
          expect(status_code).to eq 404
        end

        it "via full_url" do
          visit file.full_url
          expect(status_code).to eq 404
        end

        it "via thumb_url" do
          visit file.thumb_url
          expect(status_code).to eq 404
        end
      end

      context "with owned user" do
        before { login_cms_user }

        it "via url" do
          visit file.url
          expect(status_code).to eq 200
        end

        it "via full_url" do
          visit file.full_url
          expect(status_code).to eq 200
        end

        it "#index with new thumbnail" do
          visit file.thumb_url
          expect(status_code).to eq 200
        end

        it "#index with custom variant" do
          visit file.variants[{ width: 240, height: 180 }].url
          expect(status_code).to eq 200
        end

        it "#thumb" do
          visit "/fs/#{file.id.to_s.chars.join("/")}/_/thumb/#{file.filename}"
          expect(status_code).to eq 200
        end
      end

      context "with other user" do
        let!(:user2) { create :cms_test_user, group_ids: user.group_ids }

        before { login_user user2 }

        it "via url" do
          visit file.url
          expect(status_code).to eq 404
        end

        it "via full_url" do
          visit file.full_url
          expect(status_code).to eq 404
        end

        it "#index with new thumbnail" do
          visit file.thumb_url
          expect(status_code).to eq 404
        end

        it "#index with custom variant" do
          visit file.variants[{ width: 240, height: 180 }].url
          expect(status_code).to eq 404
        end

        it "#thumb" do
          visit "/fs/#{file.id.to_s.chars.join("/")}/_/thumb/#{file.filename}"
          expect(status_code).to eq 404
        end
      end
    end

    context "file associated to cms/page as owner_item" do
      let(:html) do
        <<~HTML.freeze
          <p><img alt="#{file.name}" src="#{file.url}" /></p>
        HTML
      end
      let!(:item) { create :cms_page, cur_site: site, cur_user: user, html: html, file_ids: [ file.id ], state: state }

      context "with public page" do
        let(:state) { "public" }

        context "without auth" do
          it "via url" do
            visit file.url
            expect(status_code).to eq 200
          end

          it "via full_url" do
            visit file.full_url
            expect(status_code).to eq 200
          end

          it "#index with new thumbnail" do
            visit file.thumb_url
            expect(status_code).to eq 200
          end

          it "#index with custom variant" do
            visit file.variants[{ width: 240, height: 180 }].url
            expect(status_code).to eq 200
          end

          it "#thumb" do
            visit "/fs/#{file.id.to_s.chars.join("/")}/_/thumb/#{file.filename}"
            expect(status_code).to eq 200
          end
        end

        context "with auth" do
          before { login_cms_user }

          it "via url" do
            visit file.url
            expect(status_code).to eq 200
          end

          it "via full_url" do
            visit file.full_url
            expect(status_code).to eq 200
          end

          it "#index with new thumbnail" do
            visit file.thumb_url
            expect(status_code).to eq 200
          end

          it "#index with custom variant" do
            visit file.variants[{ width: 240, height: 180 }].url
            expect(status_code).to eq 200
          end

          it "#thumb" do
            visit "/fs/#{file.id.to_s.chars.join("/")}/_/thumb/#{file.filename}"
            expect(status_code).to eq 200
          end
        end
      end

      context "with public page via other site" do
        let(:site2) { create :cms_site_unique }
        let(:state) { "public" }

        context "without auth" do
          it "via full_url" do
            file.site_id = site2.id
            expect(file.full_url).to start_with(site2.full_url)

            visit file.full_url
            expect(status_code).to eq 404
          end
        end

        context "with auth" do
          before { login_cms_user }

          it "via full_url" do
            file.site_id = site2.id
            expect(file.full_url).to start_with(site2.full_url)

            visit file.full_url
            expect(status_code).to eq 404
          end
        end
      end

      context "with closed page" do
        let(:state) { "closed" }

        context "without auth" do
          it "via url" do
            visit file.url
            expect(status_code).to eq 404
          end

          it "via full_url" do
            visit file.full_url
            expect(status_code).to eq 404
          end

          it "#index with new thumbnail" do
            visit file.thumb_url
            expect(status_code).to eq 404
          end

          it "#index with custom variant" do
            visit file.variants[{ width: 240, height: 180 }].url
            expect(status_code).to eq 404
          end

          it "#thumb" do
            visit "/fs/#{file.id.to_s.chars.join("/")}/_/thumb/#{file.filename}"
            expect(status_code).to eq 404
          end
        end

        context "with auth" do
          before { login_cms_user }

          it "via url" do
            visit file.url
            expect(status_code).to eq 200
          end

          it "via full_url" do
            visit file.full_url
            expect(status_code).to eq 200
          end

          it "#index with new thumbnail" do
            visit file.thumb_url
            expect(status_code).to eq 200
          end

          it "#index with custom variant" do
            visit file.variants[{ width: 240, height: 180 }].url
            expect(status_code).to eq 200
          end

          it "#thumb" do
            visit "/fs/#{file.id.to_s.chars.join("/")}/_/thumb/#{file.filename}"
            expect(status_code).to eq 200
          end
        end
      end

      context "with mypage domain" do
        let(:state) { "public" }

        before do
          site.mypage_domain = unique_domain
          site.save!

          decorator = proc do |env|
            env["HTTP_X_FORWARDED_HOST"] = site.mypage_domain
          end
          add_request_decorator Fs::FilesController, decorator
        end

        it "via url" do
          visit file.url
          expect(status_code).to eq 200
        end

        it "via thumb_url" do
          visit file.thumb_url
          expect(status_code).to eq 200
        end
      end
    end

    context "with sub-directory sub-site" do
      let!(:sub_site) { create :cms_site_subdir, parent: site, domains: site.domains, group_ids: site.group_ids }
      let(:html) do
        <<~HTML.freeze
          <p><img alt="#{file.name}" src="#{file.url}" /></p>
        HTML
      end
      let!(:item) { create :cms_page, cur_site: sub_site, cur_user: user, html: html, file_ids: [ file.id ], state: state }

      context "with public page" do
        let(:state) { "public" }

        it "via url" do
          visit file.url
          expect(status_code).to eq 200
        end

        it "via full_url" do
          visit file.full_url
          expect(status_code).to eq 200
        end

        it "via thumb_url" do
          visit file.thumb_url
          expect(status_code).to eq 200
        end
      end

      context "with public page via other site" do
        let(:site2) { create :cms_site_unique }
        let(:state) { "public" }

        it "via full_url" do
          file.site_id = site2.id
          expect(file.full_url).to start_with(site2.full_url)

          visit file.full_url
          expect(status_code).to eq 404
        end
      end
    end

    context "with sub-directory sub-site via mypage domain" do
      let(:mypage_domain) { unique_domain }
      let!(:sub_site) do
        create :cms_site_subdir, parent: site, domains: site.domains, group_ids: site.group_ids, mypage_domain: mypage_domain
      end
      let(:html) do
        <<~HTML.freeze
          <p><img alt="#{file.name}" src="#{file.url}" /></p>
        HTML
      end
      let!(:item) { create :cms_page, cur_site: sub_site, cur_user: user, html: html, file_ids: [ file.id ], state: state }
      let(:state) { "public" }

      before do
        site.mypage_domain = mypage_domain
        site.save!

        decorator = proc do |env|
          env["HTTP_X_FORWARDED_HOST"] = mypage_domain
        end
        add_request_decorator Fs::FilesController, decorator
      end

      it "via url" do
        visit file.url
        expect(status_code).to eq 200
      end

      it "via thumb_url" do
        visit file.thumb_url
        expect(status_code).to eq 200
      end
    end

    context "with sub-directory sub-site" do
      let!(:sub_site) { create :cms_site_subdir, parent: site, domains: site.domains, group_ids: site.group_ids }
      let(:html) do
        <<~HTML.freeze
          <p><img alt="#{file.name}" src="#{file.url}" /></p>
        HTML
      end
      let!(:item) { create :cms_page, cur_site: sub_site, cur_user: user, html: html, file_ids: [ file.id ], state: state }

      context "with public page" do
        let(:state) { "public" }

        it "via url" do
          visit file.url
          expect(status_code).to eq 200
        end

        it "via full_url" do
          visit file.full_url
          expect(status_code).to eq 200
        end

        it "via thumb_url" do
          visit file.thumb_url
          expect(status_code).to eq 200
        end
      end

      context "with public page via other site" do
        let(:site2) { create :cms_site_unique }
        let(:state) { "public" }

        it "via full_url" do
          file.site_id = site2.id
          expect(file.full_url).to start_with(site2.full_url)

          visit file.full_url
          expect(status_code).to eq 404
        end
      end
    end

    context "when /fs is restricted with ip addresses" do
      let!(:sub_site) do
        create(
          :cms_site_subdir, parent: site, domains: site.domains, group_ids: site.group_ids,
          file_fs_access_restriction_state: "enabled",
          file_fs_access_restriction_allowed_ip_addresses: %w(192.168.10.0/24)
        )
      end
      let(:html) do
        <<~HTML.freeze
          <p><img alt="#{file.name}" src="#{file.url}" /></p>
        HTML
      end
      let!(:item) { create :cms_page, cur_site: sub_site, cur_user: user, html: html, file_ids: [ file.id ], state: state }

      before do
        decorator = proc do |env|
          env["HTTP_X_REAL_IP"] = ip_address
        end
        add_request_decorator Fs::FilesController, decorator
      end

      context "with allowed ip address" do
        let(:state) { "public" }
        let(:ip_address) { "192.168.10.#{rand(0..255)}" }

        it "via url" do
          visit file.url
          expect(status_code).to eq 200
        end

        it "via full_url" do
          visit file.full_url
          expect(status_code).to eq 200
        end

        it "via thumb_url" do
          visit file.thumb_url
          expect(status_code).to eq 200
        end
      end

      context "with disallowed ip address" do
        let(:state) { "public" }
        let(:ip_address) { "192.168.57.#{rand(0..255)}" }

        it "via url" do
          visit file.url
          expect(status_code).to eq 404
        end

        it "via full_url" do
          visit file.full_url
          expect(status_code).to eq 404
        end

        it "via thumb_url" do
          visit file.thumb_url
          expect(status_code).to eq 404
        end
      end
    end
  end

  # https://github.com/shirasagi/shirasagi/issues/307
  context "[logo.png.png]" do
    let(:filename) { "#{Rails.root}/spec/fixtures/fs/logo.png.png" }

    context "without auth" do
      it "#index" do
        visit file.url
        expect(status_code).to eq 404
      end

      it "#thumb" do
        visit file.thumb_url
        expect(status_code).to eq 404
      end
    end

    context "with auth" do
      before { login_cms_user }

      it "#index" do
        visit file.url
        expect(status_code).to eq 200
      end

      it "#thumb" do
        visit file.thumb_url
        expect(status_code).to eq 200
      end
    end
  end

  context "error page" do
    let(:url) { "/fs/1/_/error.png" }
    let(:item) { create :cms_page, filename: "404.html", name: "404", html: unique_id.to_s }

    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    context "without auth" do
      it "when not created 404.html" do
        visit url
        expect(status_code).to eq 404
        expect(page.html.include?(item.html)).to be_falsey
      end

      it "when created 404.html" do
        item
        visit url
        expect(status_code).to eq 404
        expect(page.html.include?(item.html)).to be_truthy
      end
    end

    context "with auth" do
      before { login_cms_user }

      it "when not created 404.html" do
        visit url
        expect(status_code).to eq 404
        expect(page.html.include?(item.html)).to be_falsey
      end

      it "when created 404.html" do
        visit url
        expect(status_code).to eq 404
        expect(page.html.include?(item.html)).to be_falsey
      end
    end
  end

  after(:each) do
    Fs.rm_rf "#{Rails.root}/tmp/ss_files"
  end
end
