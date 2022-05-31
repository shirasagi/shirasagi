module SS
  module EsSupport
    module_function

    def es_hosts
      @es_hosts ||= 'http://localhost:9200'
    end

    def es_requests
      @es_requests ||= []
    end

    def es_indexes
      @es_indexes ||= {}
    end

    module Hooks
      def self.extended(obj)
        obj.class_eval do
          delegate :es_hosts, :es_requests, :es_indexes, to: ::SS::EsSupport
        end

        obj.before do
          if site.elasticsearch_hosts.blank?
            site.elasticsearch_hosts = SS::EsSupport.es_hosts
            site.save!
          end

          WebMock.reset!
          stub_request(:any, /#{::Regexp.escape(site.elasticsearch_hosts.first)}/).to_return do |request|
            ::SS::EsSupport.es_requests << request.as_json.dup

            method = request.method
            uri = request.uri.to_s
            case method
            when :head # like "ping"
              { body: '{}', status: 200, headers: { 'Content-Type' => 'application/json; charset=UTF-8' } }
            when :put
              ::SS::EsSupport.es_indexes[uri] ||= 0
              ::SS::EsSupport.es_indexes[uri] += 1
              { body: '{}', status: 200, headers: { 'Content-Type' => 'application/json; charset=UTF-8' } }
            when :delete
              if ::SS::EsSupport.es_indexes.key?(uri)
                ::SS::EsSupport.es_indexes.delete(uri)
                { body: '{}', status: 200, headers: { 'Content-Type' => 'application/json; charset=UTF-8' } }
              else
                { body: '{}', status: 404, headers: { 'Content-Type' => 'application/json; charset=UTF-8' } }
              end
            else
              # method not allowed
              { body: '{}', status: 405, headers: { 'Content-Type' => 'application/json; charset=UTF-8' } }
            end
          end
        end

        obj.after do
          WebMock.reset!
          SS::EsSupport.es_requests.clear
          SS::EsSupport.es_indexes.clear
        end
      end
    end
  end
end

RSpec.configuration.extend(SS::EsSupport::Hooks, es: true)
