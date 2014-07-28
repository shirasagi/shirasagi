# coding: utf-8
module Cms::PublicHelper
  def paginate(scope, options = {}, &block)
    if params[:public_path]
      options[:params] ||= {}
      keys = Rack::Utils.parse_nested_query(request.env['QUERY_STRING'])
      params.each_key do |k|
        next if k == "controller" || k == "action" || k == "host"
        options[:params][k] = nil unless keys.key? k
      end
      options[:params]["public_path"] = "#{request.env['REQUEST_PATH']}".sub(/^\//, "")
      super(scope, options, &block)
    else
      super(scope, options, &block)
    end
  end
end
