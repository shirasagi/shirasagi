# coding: utf-8
class Cms::Task
  include SS::Task::Model
  include SS::Reference::Site

  belongs_to :node, class_name: "Cms::Node"

  class << self
    def generate_nodes(opts = {})
      return generate_nodes_with_node opts if opts[:node]

      cond = {}
      cond[:host] = opts[:site] if opts[:site]

      Cms::Site.where(cond).each do |site|
        run name: "cms:generate_nodes", site_id: site.id, node_id: nil do |task|
          Cms::Task::NodesController.new.generate task: task, site: site
        end
      end
    end

    def generate_nodes_with_node(opts = {})
      site = Cms::Site.find_by host: opts[:site]
      node = Cms::Node.site(site).find_by filename: opts[:node]

      run name: "cms:generate_nodes", site_id: site.id, node_id: node.id do |task|
        Cms::Task::NodesController.new.generate_with_node task: task, site: site, node: node
      end
    end

    def generate_pages(opts = {})
      return generate_pages_with_node opts if opts[:node]

      cond = {}
      cond[:host] = opts[:site] if opts[:site]

      Cms::Site.where(cond).each do |site|
        run name: "cms:generate_pages", site_id: site.id, node_id: nil do |task|
          Cms::Task::PagesController.new.generate task: task, site: site
        end
      end
    end

    def generate_pages_with_node(opts = {})
      site = Cms::Site.find_by host: opts[:site]
      node = Cms::Node.site(site).find_by filename: opts[:node]

      run name: "cms:generate_pages", site_id: site.id, node_id: node.id do |task|
        Cms::Task::PagesController.new.generate_with_node task: task, site: site, node: node
      end
    end

    def release_pages(opts = {})
      cond = {}
      cond[:host] = opts[:site] if opts[:site]

      Cms::Site.where(cond).each do |site|
        run name: "cms:release_pages", site_id: site.id do |task|
          Cms::Task::PagesController.new.release task: task, site: site
        end
      end
    end

    def remove_pages(opts = {})
      cond = {}
      cond[:host] = opts[:site] if opts[:site]

      Cms::Site.where(cond).each do |site|
        run name: "cms:remove_pages", site_id: site.id do |task|
          Cms::Task::PagesController.new.remove task: task, site: site
        end
      end
    end
  end
end
