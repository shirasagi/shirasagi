require 'docker'

module SS
  module EsSupport
    module_function

    def es_port
      @es_port ||= rand(29_200..39_200)
    end

    def es_port=(port)
      @es_port = port
    end

    def es_url
      "http://localhost:#{SS::EsSupport.es_port}"
    end

    def docker_image_id
      @docker_image_id ||= "shirasagi/elasticsearch"
    end

    def docker_container_borrowed
      @docker_borrowed
    end

    def docker_container_borrowed=(borrowed)
      @docker_borrowed = borrowed
    end

    def docker_container
      @docker_container
    end

    def docker_container=(container)
      @docker_container = container
    end

    def init
      RSpec.configuration.extend(SS::EsSupport::Hooks, es: true)
      RSpec.configuration.after(:suite) do
        SS::EsSupport.after_suite
      end
    end

    def before_example
      container = SS::EsSupport.docker_container
      return if container.present? # already running

      ENV["ES_CONTAINER_ID"].try do |container_id|
        if container_id.present?
          container = Docker::Container.get(container_id) rescue nil
        end
        if container
          SS::EsSupport.docker_container_borrowed = true
          SS::EsSupport.docker_container = container
          es_port = container.info["HostConfig"]["PortBindings"]["9200/tcp"][0]["HostPort"].to_i
          SS::EsSupport.es_port = es_port

          puts "use container '#{container.id[0, 12]}' listening on #{es_port}"
        end
      end

      container = SS::EsSupport.docker_container
      return if container.present? # already running

      image_id = SS::EsSupport.docker_image_id
      image = Docker::Image.get(image_id) rescue nil
      if image.blank?
        puts "image '#{image_id}' is not found"
        return
      end

      es_port = SS::EsSupport.es_port
      container = Docker::Container.create(
        'Image' => image_id,
        'ExposedPorts' => { '9200/tcp' => {} },
        'Env' => %w(discovery.type=single-node),
        'HostConfig' => {
          'PortBindings' => {
            '9200/tcp' => [{ 'HostPort' => es_port.to_s }]
          }
        }
      )

      container.start
      Timeout.timeout(60) do
        loop do
          break if container.logs(stdout: true).include?("Cluster health status changed from [YELLOW] to [GREEN]")

          sleep 0.1
        end
      end

      SS::EsSupport.docker_container_borrowed = false
      SS::EsSupport.docker_container = container
      puts "image '#{image_id}' successfully launched as container '#{container.id[0, 12]}' listening on #{es_port}"
    rescue => e
      puts "#{e}: failed to start '#{SS::EsSupport.docker_image_id}'"
      puts container.logs(stdout: true) if container
      raise
    end

    def after_example
    end

    def after_suite
      container = SS::EsSupport.docker_container
      return if container.blank?

      SS::EsSupport.docker_container = nil
      unless SS::EsSupport.docker_container_borrowed
        container.stop
        container.delete(force: true)
        puts "container '#{container.id[0, 12]}' is deleted"
      end
    end

    module Hooks
      def self.extended(obj)
        obj.class_eval do
          delegate :es_url, to: ::SS::EsSupport
        end

        obj.before(:example) do
          SS::EsSupport.before_example

          if site.elasticsearch_hosts.blank?
            site.elasticsearch_hosts = SS::EsSupport.es_url
            site.save!
          end
        end
        obj.after(:example) do
          SS::EsSupport.after_example
        end
      end
    end
  end
end

SS::EsSupport.init
