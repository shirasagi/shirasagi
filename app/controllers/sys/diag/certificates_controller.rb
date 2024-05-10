class Sys::Diag::CertificatesController < ApplicationController
  include Sys::BaseFilter
  include Sys::CrudFilter

  navi_view "sys/diag/main/navi"
  menu_view nil

  private

  def set_crumbs
    @crumbs << [ t("sys.diag"), sys_diag_main_path ]
    @crumbs << ["SSL/TLS Certificate", url_for(action: :show)]
  end

  # override ss/crud_filter#set_item
  def set_item
  end

  public

  def show
    raise "403" unless SS::User.allowed?(:edit, @cur_user)
    render
  end

  def update
    safe_params = params.require(:item).permit(:host, :port)
    @host = safe_params[:host]
    @port = safe_params[:port]
    if @host.blank?
      @errors = [ "Host is blank" ]
      render template: "show"
      return
    end
    unless @port.numeric?
      @errors = [ "Port is invalid" ]
      render template: "show"
      return
    end

    tmpdir = Rails.root.join("tmp").to_s
    Tempfile.open("cert", tmpdir) do |stdout|
      Tempfile.open("cert", tmpdir) do |stderr|
        exit_status = SS::Command.run(
          "openssl", "s_client", "-connect", "#{@host}:#{@port}", "-showcerts",
          stdout: stdout, stderr: stderr)
        if exit_status == 0
          @result = ::File.read(stdout.path)
        else
          @errors = [ "command 'openssl' is failed" ]
          @errors << ::File.read(stderr.path)
        end
      end
    end

    render template: "show"
  rescue Errno::ENOENT
    @errors = [ "command 'openssl' is not found" ]
    render template: "show"
    return
  end
end
