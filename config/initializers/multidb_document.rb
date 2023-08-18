module Mongoid
  module Document
    module ClassMethods
      def store_in_repl_master
        [:repl_master, :default_post].each do |client_name|
          next unless Mongoid::Config.clients[client_name]
          store_in client: client_name
          break
        end
      end

      def store_in_default_post
        if Mongoid::Config.clients[:default_post]
          store_in client: :default_post
        end
      end

      def with_repl_master(&block)
        client_name = :repl_master
        client = Mongoid::Config.clients[:repl_master]

        if client.nil?
          client_name = persistence_context.send(:client_name)
          client = Mongoid::Config.clients[client_name]
        end

        if block
          self.with(client: client_name, database: client[:database], &block)
        else
          self.with(client: client_name, database: client[:database]) { |criteria| criteria }
        end
      end

      def mongo_client_options
        options = persistence_context.options
        return { client: options[:client], database: options[:database] }.compact if options.present?
        { client: self.storage_options[:client], database: self.database_name }.compact
      end
    end

    def mongo_client_options
      options = persistence_context.options
      return { client: options[:client], database: options[:database] }.compact if options.present?
      { client: self.class.storage_options[:client], database: self.class.database_name }.compact
    end

    def with_repl_master(&block)
      client_name = :repl_master
      client = Mongoid::Config.clients[:repl_master]

      if client.nil?
        client_name = persistence_context.send(:client_name)
        client = Mongoid::Config.clients[client_name]
      end

      if block
        self.with(client: client_name, database: client[:database], &block)
      else
        self.with(client: client_name, database: client[:database]) { |criteria| criteria }
      end
    end
  end
end
