require 'spec_helper'

describe "sys_diag_servers", type: :feature, dbscope: :example do
  before do
    @save_cpuinfo = Sys::Diag::ServersController::PROC_CPUINFO_FILE_PATH
    @save_meminfo = Sys::Diag::ServersController::PROC_MEMINFO_FILE_PATH
    Sys::Diag::ServersController.send(:remove_const, :PROC_CPUINFO_FILE_PATH)
    Sys::Diag::ServersController.send(:remove_const, :PROC_MEMINFO_FILE_PATH)
    Sys::Diag::ServersController.const_set(:PROC_CPUINFO_FILE_PATH, "#{Rails.root}/spec/fixtures/sys/diag/cpuinfo-1")
    Sys::Diag::ServersController.const_set(:PROC_MEMINFO_FILE_PATH, "#{Rails.root}/spec/fixtures/sys/diag/meminfo-1")
    login_sys_user
  end

  after do
    Sys::Diag::ServersController.send(:remove_const, :PROC_CPUINFO_FILE_PATH)
    Sys::Diag::ServersController.send(:remove_const, :PROC_MEMINFO_FILE_PATH)
    Sys::Diag::ServersController.const_set(:PROC_CPUINFO_FILE_PATH, @save_cpuinfo)
    Sys::Diag::ServersController.const_set(:PROC_MEMINFO_FILE_PATH, @save_meminfo)
  end

  it do
    visit sys_diag_server_path

    within "#server-info" do
      expect(page).to have_css("dt", text: "uptime")
    end

    within "#cpu-info" do
      expect(page).to have_css("dt", text: "processor")
      expect(page).to have_css("dt", text: "power management")
    end

    within "#mem-info" do
      expect(page).to have_css("dt", text: "MemTotal")
      expect(page).to have_css("dt", text: "DirectMap2M")
    end

    within "#http-env-list" do
      expect(page).to have_css("dt", text: "CONTENT_LENGTH")
      expect(page).to have_css("dt", text: "SERVER_PORT")
    end

    within "#rack-env-list" do
      expect(page).to have_css("dt", text: "rack.errors")
      expect(page).to have_css("dt", text: "rack.version")
    end

    within "#rails-env-list" do
      expect(page).to have_css("dt", text: "action_controller.instance")
      expect(page).to have_css("dt", text: "action_dispatch.use_authenticated_cookie_encryption")
    end

    within "#other-env-list" do
      expect(page).to have_css("dt", text: "http_accept_language.parser")
    end
  end
end
