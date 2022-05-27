require 'spec_helper'

describe "cms_generate_nodes", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }

  let(:index_path) { cms_generate_nodes_path site.id }
  let(:web01_path) { cms_segment_generate_nodes_path site.id, segment: "web01" }
  let(:web02_path) { cms_segment_generate_nodes_path site.id, segment: "web02" }
  let(:web03_path) { cms_segment_generate_nodes_path site.id, segment: "web03" }

  def find_task(segment)
    Cms::Task.site(site).where(name: "cms:generate_nodes", node_id: nil, segment: segment).first
  end

  def find_tasks
    [find_task(nil), find_task("web01"), find_task("web02"), find_task("web03")]
  end

  context "without segments" do
    let(:segments) { [] }

    before do
      @save_generate_segments = SS.config.cms.generate_segments
      SS.config.replace_value_at(:cms, :generate_segments, { "node" => { site.host => segments } })
    end

    after do
      SS.config.replace_value_at(:cms, :generate_segments, @save_generate_segments)
    end

    it "#index" do
      login_cms_user
      visit index_path
      expect(current_path).to eq index_path
      expect(page).to have_no_css("a[href=\"#{web01_path}\"]")
      expect(page).to have_no_css("a[href=\"#{web02_path}\"]")
      expect(page).to have_no_css("a[href=\"#{web03_path}\"]")

      task, task_web01, task_web02, task_web03 = find_tasks
      expect(task.state).to eq "stop"
      expect(task_web01).to eq nil
      expect(task_web02).to eq nil
      expect(task_web03).to eq nil

      # run
      within "form#task-form" do
        click_button I18n.t("ss.buttons.run")
      end
      expect(current_path).to eq index_path
      expect(page).to have_css('#notice', text: I18n.t('ss.tasks.started'))

      task, task_web01, task_web02, task_web03 = find_tasks
      expect(task.state).to eq "ready"
      expect(task_web01).to eq nil
      expect(task_web02).to eq nil
      expect(task_web03).to eq nil
    end
  end

  context "with segments" do
    let(:segments) { %w(web01 web02 web03) }

    before do
      @save_generate_segments = SS.config.cms.generate_segments
      SS.config.replace_value_at(:cms, :generate_segments, { "node" => { site.host => segments } })
    end

    after do
      SS.config.replace_value_at(:cms, :generate_segments, @save_generate_segments)
    end

    it "#index" do
      login_cms_user
      visit index_path

      expect(current_path).to eq web01_path
      expect(page).to have_css("a[href=\"#{web01_path}\"]")
      expect(page).to have_css("a[href=\"#{web02_path}\"]")
      expect(page).to have_css("a[href=\"#{web03_path}\"]")

      task, task_web01, task_web02, task_web03 = find_tasks
      expect(task).to eq nil
      expect(task_web01.state).to eq "stop"
      expect(task_web02).to eq nil
      expect(task_web03).to eq nil

      first("a[href=\"#{web02_path}\"]").click
      expect(current_path).to eq web02_path

      task, task_web01, task_web02, task_web03 = find_tasks
      expect(task).to eq nil
      expect(task_web01.state).to eq "stop"
      expect(task_web02.state).to eq "stop"
      expect(task_web03).to eq nil

      first("a[href=\"#{web03_path}\"]").click
      expect(current_path).to eq web03_path

      task, task_web01, task_web02, task_web03 = find_tasks
      expect(task).to eq nil
      expect(task_web01.state).to eq "stop"
      expect(task_web02.state).to eq "stop"
      expect(task_web03.state).to eq "stop"

      # run web01
      first("a[href=\"#{web01_path}\"]").click
      expect(current_path).to eq web01_path
      within "form#task-form" do
        click_button I18n.t("ss.buttons.run")
      end
      expect(current_path).to eq web01_path
      expect(page).to have_css('#notice', text: I18n.t('ss.tasks.started'))

      task, task_web01, task_web02, task_web03 = find_tasks
      expect(task).to eq nil
      expect(task_web01.state).to eq "ready"
      expect(task_web02.state).to eq "stop"
      expect(task_web03.state).to eq "stop"

      # run web02
      first("a[href=\"#{web02_path}\"]").click
      expect(current_path).to eq web02_path
      within "form#task-form" do
        click_button I18n.t("ss.buttons.run")
      end
      expect(current_path).to eq web02_path
      expect(page).to have_css('#notice', text: I18n.t('ss.tasks.started'))

      task, task_web01, task_web02, task_web03 = find_tasks
      expect(task).to eq nil
      expect(task_web01.state).to eq "ready"
      expect(task_web02.state).to eq "ready"
      expect(task_web03.state).to eq "stop"

      # run web03
      first("a[href=\"#{web03_path}\"]").click
      expect(current_path).to eq web03_path
      within "form#task-form" do
        click_button I18n.t("ss.buttons.run")
      end
      expect(current_path).to eq web03_path
      expect(page).to have_css('#notice', text: I18n.t('ss.tasks.started'))

      task, task_web01, task_web02, task_web03 = find_tasks
      expect(task).to eq nil
      expect(task_web01.state).to eq "ready"
      expect(task_web02.state).to eq "ready"
      expect(task_web03.state).to eq "ready"
    end
  end
end
