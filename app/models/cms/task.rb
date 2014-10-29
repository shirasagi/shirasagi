class Cms::Task
  include SS::Task::Model
  include SS::Reference::Site

  belongs_to :node, class_name: "Cms::Node"

  class << self
    private
      def find_sites(opts)
        return Cms::Site unless opts[:host]
        Cms::Site.where host: opts[:host]
      end

      def find_node(site, opts)
        return nil unless opts[:node]
        Cms::Node.site(site).find_by filename: opts[:node]
      end

    public
      def generate_nodes(opts = {})
        find_sites(opts).each do |site|
          node    = find_node site, opts
          node_id = node ? node.id : nil

          ready name: "cms:generate_nodes", site_id: site.id, node_id: node_id do |task|
            task.process Cms::Agents::Tasks::NodesController, :generate, site: site, node: node
          end
        end
      end

      def generate_pages(opts = {})
        find_sites(opts).each do |site|
          node    = find_node site, opts
          node_id = node ? node.id : nil

          ready name: "cms:generate_pages", site_id: site.id, node_id: node_id do |task|
            task.process Cms::Agents::Tasks::PagesController, :generate, site: site, node: node
          end
        end
      end

      def update_pages(opts = {})
        find_sites(opts).each do |site|
          node    = find_node site, opts
          node_id = node ? node.id : nil

          ready name: "cms:update_pages", site_id: site.id, node_id: node_id do |task|
            task.process Cms::Agents::Tasks::PagesController, :update, site: site, node: node
          end
        end
      end

      def release_pages(opts = {})
        find_sites(opts).each do |site|
          ready name: "cms:release_pages", site_id: site.id do |task|
            task.process Cms::Agents::Tasks::PagesController, :release, site: site
          end
        end
      end

      def remove_pages(opts = {})
        find_sites(opts).each do |site|
          ready name: "cms:remove_pages", site_id: site.id do |task|
            task.process Cms::Agents::Tasks::PagesController, :remove, site: site
          end
        end
      end
  end
end
