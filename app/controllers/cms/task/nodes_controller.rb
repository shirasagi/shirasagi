# coding: utf-8
class Cms::Task::NodesController < ApplicationController
  include Cms::ReleaseFilter::Page

  public
    def generate(opts)
      return puts "config.cms.serve_static_pages is false" unless SS.config.cms.serve_static_pages

      SS::Site.where(opts[:site] ? { host: opts[:site] } : {}).each do |site|
        @cur_site = site
        task_cond = { name: "cms:node:generate", site_id: @cur_site.id }

        @task = Cms::Task.find_or_create_by task_cond
        @task.run do
          Cms::Node.site(@cur_site).public.each do |node|
            next unless node.public_node?

            cname = node.route.sub("/", "/task/node/").camelize.pluralize + "Controller"
            klass = cname.constantize rescue nil
            next if klass.nil? || klass.to_s != cname

            klass.new.generate(@task, node)
          end
        end
      end
    end
end
