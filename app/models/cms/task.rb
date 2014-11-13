class Cms::Task
  include SS::Task::Model
  include SS::Reference::Site

  belongs_to :node, class_name: "Cms::Node"

  class << self
    private
      def find_sites(opts)
        return Cms::Site unless opts[:site]
        Cms::Site.where host: opts[:site]
      end

      def find_node(site, opts)
        return nil unless opts[:node]
        Cms::Node.site(site).find_by filename: opts[:node]
      end

      def process_with_site(task_name, controller, action, opts)
        find_sites(opts).each do |site|
          ready name: task_name, site_id: site.id do |task|
            task.process controller, action, site: site
          end
        end
      end

      def process_with_node(task_name, controller, action, opts)
        find_sites(opts).each do |site|
          node    = find_node site, opts
          node_id = node ? node.id : nil

          ready name: task_name, site_id: site.id, node_id: node_id do |task|
            task.process controller, action, site: site, node: node
          end
        end
      end

    public
      def generate_nodes(opts = {})
        process_with_node "cms:generate_nodes", Cms::Agents::Tasks::NodesController, :generate, opts
      end

      def generate_pages(opts = {})
        process_with_node "cms:generate_pages", Cms::Agents::Tasks::PagesController, :generate, opts
      end

      def update_pages(opts = {})
        process_with_node "cms:update_pages", Cms::Agents::Tasks::PagesController, :update, opts
      end

      def release_pages(opts = {})
        process_with_site "cms:release_pages", Cms::Agents::Tasks::PagesController, :release, opts
      end

      def remove_pages(opts = {})
        process_with_site "cms:remove_pages", Cms::Agents::Tasks::PagesController, :remove, opts
      end
  end
end
