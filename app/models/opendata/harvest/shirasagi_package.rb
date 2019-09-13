class Opendata::Harvest::ShirasagiPackage
  attr_reader :url, :api_path

  private

  def validate_result(api, result)
    raise "#{api} failed #{result}" if result["success"] != true
  end

  public

  def initialize(url, opts = {})
    @url = url
    @api_path = opts[:api_path].presence || "api"
    @http_basic_authentication = opts[:http_basic_authentication] if opts[:http_basic_authentication].present?
  end

  def open_options
    opts = {}
    opts[:http_basic_authentication] = @http_basic_authentication if @http_basic_authentication
    opts[:read_timeout] = 10
    opts
  end

  def package_list_url
    ::File.join(url, api_path, "package_list")
  end

  def package_show_url(id = nil)
    if id
      ::File.join(url, api_path, "package_show") + "?id=#{id}"
    else
      ::File.join(url, api_path, "package_show")
    end
  end

  ## package(dataset) apis

  def package_list
    result = ::URI.open(package_list_url, open_options).read
    result = ::JSON.parse(result)
    validate_result("package_list", result)
    result["result"]
  end

  def package_show(id)
    result = ::URI.open(package_show_url(id), open_options).read
    result = ::JSON.parse(result)
    validate_result("package_show", result)
    result["result"]
  end
end
