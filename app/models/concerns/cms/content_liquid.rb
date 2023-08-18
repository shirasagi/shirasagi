module Cms::ContentLiquid
  extend ActiveSupport::Concern

  included do
    liquidize do
      export :id
      export :name
      export :index_name
      export :url
      export :full_url
      export :basename
      export :filename
      export :order
      export :date
      export :released
      export :released_type
      export :updated
      export :created
      export :parent do
        p = self.parent
        p == false ? nil : p
      end
      export :css_class do |context|
        issuer = context.registers[:cur_part] || context.registers[:cur_node]
        template_variable_handler_class("class", issuer)
      end
      export :new? do |context|
        issuer = context.registers[:cur_part] || context.registers[:cur_node]
        issuer.respond_to?(:in_new_days?) && issuer.in_new_days?(self.date)
      end
      export :current? do |context|
        # ApplicationHelper#current_url?
        cur_path = context.registers[:cur_path]
        next false if cur_path.blank?

        current = cur_path.sub(/\?.*/, "")
        next false if current.delete("/").blank?
        next true if self.url.sub(/\/index\.html$/, "/") == current.sub(/\/index\.html$/, "/")
        next true if current =~ /^#{::Regexp.escape(url)}(\/|\?|$)/

        false
      end
    end
  end
end
