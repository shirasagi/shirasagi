require 'spec_helper'

describe Article::Page, dbscope: :example do
  let!(:site) { cms_site }
  let!(:user) { cms_user }
  let!(:node) { create :article_node_page, cur_site: site }

  let(:now) { Time.zone.now.change(sec: 0) }
  let(:name) { "name-#{unique_id}" }
  let(:name2) { "name-#{unique_id}" }
  let(:basename) { "#{unique_id}.html" }
  let(:close_date) { now + 1.day }
  let!(:master_page) do
    create :article_page, cur_site: site, cur_node: node, name: name, basename: basename, close_date: close_date, state: "public"
  end
  let!(:branch_page) do
    branch_page = master_page.new_clone
    branch_page.master = master_page
    branch_page.name = name2
    branch_page.save!

    branch_page = Article::Page.find(branch_page.id)
    branch_page.cur_site = site
    branch_page
  end

  it do
    expect(master_page.site_id).to eq site.id
    expect(master_page.state).to eq "public"
    expect(master_page.name).to eq name
    expect(master_page.filename).to eq "#{node.filename}/#{basename}"
    expect(master_page.close_date).to eq close_date
    expect(::File.size(master_page.path)).to be > 0

    expect(branch_page.site_id).to eq site.id
    expect(branch_page.state).to eq "closed"
    expect(branch_page.name).to eq name2
    expect(branch_page.filename).to eq "#{node.filename}/#{branch_page.id}.html"
    expect(branch_page.close_date).to eq close_date
    expect(::File.exist?(branch_page.path)).to be_falsey

    travel_to = close_date + 1.minute
    Timecop.travel(travel_to) do
      # 3. 公開終了日を経過し公開中のページ（1）が非公開になる
      expect do
        Cms::Page::ReleaseJob.bind(site_id: node.site_id, node_id: node.id).perform_now
      end.to output(/#{::Regexp.escape(master_page.full_url)}/).to_stdout

      master_page.reload
      expect(master_page.site_id).to eq site.id
      expect(master_page.state).to eq "closed"
      expect(master_page.name).to eq name
      expect(master_page.filename).to eq "#{node.filename}/#{basename}"
      expect(master_page.close_date).to be_blank
      expect(::File.exist?(master_page.path)).to be_falsey

      # 4. 差し替えページ（2）を公開保存
      task = SS::Task.find_or_create_for_model(master_page, site: site)
      result = task.run_with do
        branch_page.state = "public"
        branch_page.save
      end

      expect(result).to be_falsey
      message = I18n.t("errors.messages.greater_than", count: I18n.l(travel_to))
      expect(branch_page.errors.full_messages).to include(/#{::Regexp.escape(message)}/)

      master_page.reload
      expect(master_page.site_id).to eq site.id
      expect(master_page.state).to eq "closed"
      expect(master_page.name).to eq name
      expect(master_page.filename).to eq "#{node.filename}/#{basename}"
      expect(master_page.close_date).to be_blank
      expect(::File.exist?(master_page.path)).to be_falsey

      branch_page.reload
      expect(branch_page.site_id).to eq site.id
      expect(branch_page.state).to eq "closed"
      expect(branch_page.name).to eq name2
      expect(branch_page.filename).to eq "#{node.filename}/#{branch_page.id}.html"
      expect(branch_page.close_date).to eq close_date
      expect(::File.exist?(branch_page.path)).to be_falsey
    end
  end
end
