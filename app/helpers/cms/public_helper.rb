# coding: utf-8
module Cms::PublicHelper
  def paginate(scope, options = {}, &block)
    if params[:public_path]
      options[:params] ||= {}
      keys = Rack::Utils.parse_nested_query(request.env['QUERY_STRING'])
      params.each_key do |k|
        next if %w(controller action site).include?(k)
        options[:params][k] = nil unless keys.key? k
      end
      options[:params]["public_path"] = "#{request.env['REQUEST_PATH']}".sub(/^\//, "")
    end
    super(scope, options, &block)
  end
end
