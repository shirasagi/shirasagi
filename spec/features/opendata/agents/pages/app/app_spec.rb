require 'spec_helper'

describe "opendata_agents_pages_app", dbscope: :example, js: true do
  def create_appfile(app, file, format)
    appfile = app.appfiles.new(text: "index", format: format)
    appfile.in_file = file
    appfile.save
    appfile
  end

  let(:site) { cms_site }
  let(:layout) { create_cms_layout }
  let!(:node) { create :opendata_node_app, cur_site: site, name: "opendata_app", layout_id: layout.id }
  let!(:node_member) { create :opendata_node_member, cur_site: site, layout_id: layout.id }
  let!(:node_mypage) { create :opendata_node_mypage, cur_site: site, filename: "mypage", layout_id: layout.id }
  let!(:node_mypage_idea) { create :opendata_node_my_idea, cur_site: site, cur_node: node_mypage, layout_id: layout.id }
  let!(:category) { create :opendata_node_category, cur_site: site, basename: "opendata_category1", layout_id: layout.id }
  let!(:area) { create :opendata_node_area, cur_site: site, basename: "opendata_area_1", layout_id: layout.id }
  let!(:node_search) { create :opendata_node_search_app, cur_site: site, layout_id: layout.id }

  let!(:node_login) { create :member_node_login, cur_site: site, redirect_url: node.url, layout_id: layout.id }

  before do
    login_opendata_member(site, node_login)
  end

  after do
    logout_opendata_member(site, node_login)
  end

  context "show url app" do
    let!(:node_search_dataset) { create(:opendata_node_search_dataset, cur_site: site, layout_id: layout.id) }
    let(:node_ds) { create :opendata_node_dataset, cur_site: site, basename: "opendata_dataset1", layout_id: layout.id }
    let(:dataset) { create(:opendata_dataset, cur_site: site, cur_node: node_ds, layout_id: layout.id) }
    let(:app) do
      create(:opendata_app, cur_site: site, cur_node: node, layout_id: layout.id,
             appurl: "http://dev.ouropendata.jp", category_ids: [ category.id ], area_ids: [ area.id ],
             dataset_ids: [ dataset.id ])
    end

    context "with default options" do
      it do
        visit app.full_url
        expect(current_path).to eq app.url
        expect(page).to have_css("h1.name", text: app.name)
        expect(page).to have_css(".side-right .point .count")
        expect(page).not_to have_css(".side-right .download-all", visible: false)
        expect(page).to have_css(".categories")
        expect(page).to have_css(".text", text: app.text.split("\n")[0])
        expect(page).to have_css(".detail #tabs .names #url")
        expect(page).to have_css(".detail #tabs .names #dataset")
        expect(page).to have_css(".detail #tabs .names #idea")
        expect(page).to have_css(".detail #tabs .tab-body #tab-url")
        expect(page).not_to have_css(".detail #tabs .tab-body #tab-dataset", visible: true)
        expect(page).to have_css(".detail #tabs .tab-body #tab-dataset", visible: false)
        expect(page).not_to have_css(".detail #tabs .tab-body #tab-idea", visible: true)
        expect(page).to have_css(".detail #tabs .tab-body #tab-idea", visible: false)
        expect(page).not_to have_css(".detail .author dt", text: "実行回数", visible: false)
        expect(page).to have_css(".detail .author dt", text: "ライセンス")
        expect(page).to have_css(".detail .author dt", text: "更新日時")
      end
    end

    context "when point is hide" do
      before do
        node.show_point = 'hide'
        node.save!

        app.touch
        app.save!
      end

      it do
        visit app.full_url
        expect(current_path).to eq app.url
        expect(page).to have_css("h1.name", text: app.name)
        expect(page).not_to have_css(".side-right .point", visible: false)
        expect(page).to have_css(".categories")
      end
    end

    context "when dataset is disabled" do
      before do
        site.dataset_state = 'disabled'
        site.save!

        app.touch
        app.save!
      end

      it do
        visit app.full_url
        expect(current_path).to eq app.url
        expect(page).to have_css("h1.name", text: app.name)
        expect(page).to have_css(".detail #tabs .names #url")
        expect(page).not_to have_css(".detail #tabs .names #dataset", visible: false)
        expect(page).to have_css(".detail #tabs .names #idea")
        expect(page).to have_css(".detail #tabs .tab-body #tab-url")
        expect(page).not_to have_css(".detail #tabs .tab-body #tab-dataset", visible: false)
        expect(page).to have_css(".detail #tabs .tab-body #tab-idea", visible: false)
      end
    end

    context "when idea is disabled" do
      before do
        site.idea_state = 'disabled'
        site.save!

        app.touch
        app.save!
      end

      it do
        visit app.full_url
        expect(current_path).to eq app.url
        expect(page).to have_css("h1.name", text: app.name)
        expect(page).to have_css(".detail #tabs .names #url")
        expect(page).to have_css(".detail #tabs .names #dataset")
        expect(page).not_to have_css(".detail #tabs .names #idea", visible: false)
        expect(page).to have_css(".detail #tabs .tab-body #tab-url")
        expect(page).to have_css(".detail #tabs .tab-body #tab-dataset", visible: false)
        expect(page).not_to have_css(".detail #tabs .tab-body #tab-idea", visible: false)
      end
    end

    context "when dataset and idea is disabled" do
      before do
        site.dataset_state = 'disabled'
        site.idea_state = 'disabled'
        site.save!

        app.touch
        app.save!
      end

      it do
        visit app.full_url
        expect(current_path).to eq app.url
        expect(page).to have_css("h1.name", text: app.name)
        expect(page).not_to have_css(".detail #tabs .names")
        expect(page).to have_css(".detail #tabs .tab-body #tab-url")
        expect(page).not_to have_css(".detail #tabs .tab-body #tab-dataset")
        expect(page).not_to have_css(".detail #tabs .tab-body #tab-idea")
      end
    end
  end

  context "show html app" do
    let(:file_path) { Rails.root.join("spec", "fixtures", "opendata", "index.html") }
    let(:file) { Fs::UploadedFile.create_from_file(file_path, basename: "spec") }
    let(:jsfile_path) { Rails.root.join("spec", "fixtures", "opendata", "test.js") }
    let(:jsfile) { Fs::UploadedFile.create_from_file(jsfile_path, basename: "spec") }
    let(:cssfile_path) { Rails.root.join("spec", "fixtures", "opendata", "test.css") }
    let(:cssfile) { Fs::UploadedFile.create_from_file(cssfile_path, basename: "spec") }
    let(:app) do
      create :opendata_app, cur_site: site, cur_node: node, filename: "#{unique_id}.html", layout_id: layout.id
    end

    before do
      create_appfile(app, file, "HTML")
      create_appfile(app, jsfile, "JS")
      create_appfile(app, cssfile, "CSS")
    end

    context "with default options" do
      it do
        visit app.full_url
        expect(current_path).to eq app.url
        expect(page).to have_css("h1.name", text: app.name)
        expect(page).to have_css(".side-right .point .count")
        expect(page).to have_css(".side-right .download-all")
        expect(page).to have_css(".categories")
        expect(page).to have_css(".text", text: app.text.split("\n")[0])
        expect(page).to have_css(".detail #tabs .names #play")
        expect(page).to have_css(".detail #tabs .names #html")
        expect(page).to have_css(".detail #tabs .names #css")
        expect(page).to have_css(".detail #tabs .names #js")
        expect(page).to have_css(".detail #tabs .names #sample")
        expect(page).to have_css(".detail #tabs .names #dataset")
        expect(page).to have_css(".detail #tabs .names #idea")
        expect(page).to have_css(".detail #tabs .tab-body #tab-play")
        expect(page).to have_css(".detail #tabs .tab-body #tab-html", visible: false)
        expect(page).to have_css(".detail #tabs .tab-body #tab-css", visible: false)
        expect(page).to have_css(".detail #tabs .tab-body #tab-js", visible: false)
        expect(page).to have_css(".detail #tabs .tab-body #tab-sample", visible: false)
        expect(page).to have_css(".detail #tabs .tab-body #tab-dataset", visible: false)
        expect(page).to have_css(".detail #tabs .tab-body #tab-idea", visible: false)
        expect(page).to have_css(".detail .author dt", text: "実行回数")
        expect(page).to have_css(".detail .author dt", text: "ライセンス")
        expect(page).to have_css(".detail .author dt", text: "更新日時")
      end
    end

    context "when point is hide" do
      before do
        node.show_point = 'hide'
        node.save!

        app.touch
        app.save!
      end

      it do
        visit app.full_url
        expect(current_path).to eq app.url
        expect(page).to have_css("h1.name", text: app.name)
        expect(page).not_to have_css(".side-right .point", visible: false)
        expect(page).to have_css(".side-right .download-all")
      end
    end

    context "when dataset is disabled" do
      before do
        site.dataset_state = 'disabled'
        site.save!

        app.touch
        app.save!
      end

      it do
        visit app.full_url
        expect(current_path).to eq app.url
        expect(page).to have_css("h1.name", text: app.name)
        expect(page).not_to have_css(".detail #tabs .names #dataset", visible: false)
        expect(page).to have_css(".detail #tabs .names #idea")
        expect(page).not_to have_css(".detail #tabs .tab-body #tab-dataset", visible: false)
        expect(page).to have_css(".detail #tabs .tab-body #tab-idea", visible: false)
      end
    end

    context "when idea is disabled" do
      before do
        site.idea_state = 'disabled'
        site.save!

        app.touch
        app.save!
      end

      it do
        visit app.full_url
        expect(current_path).to eq app.url
        expect(page).to have_css("h1.name", text: app.name)
        expect(page).to have_css(".detail #tabs .names #dataset")
        expect(page).not_to have_css(".detail #tabs .names #idea", visible: false)
        expect(page).to have_css(".detail #tabs .tab-body #tab-dataset", visible: false)
        expect(page).not_to have_css(".detail #tabs .tab-body #tab-idea", visible: false)
      end
    end

    context "when dataset and idea is disabled" do
      before do
        site.dataset_state = 'disabled'
        site.idea_state = 'disabled'
        site.save!

        app.touch
        app.save!
      end

      it do
        visit app.full_url
        expect(current_path).to eq app.url
        expect(page).to have_css("h1.name", text: app.name)
        expect(page).not_to have_css(".detail #tabs .names #dataset", visible: false)
        expect(page).not_to have_css(".detail #tabs .names #idea", visible: false)
        expect(page).not_to have_css(".detail #tabs .tab-body #tab-dataset", visible: false)
        expect(page).not_to have_css(".detail #tabs .tab-body #tab-idea", visible: false)
      end
    end
  end
end
