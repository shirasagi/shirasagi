module SS::Addon
  def self.extended(mod)
    mod.extend SS::Translation
  end

  public
    def addon_name
      SS::Addon::Name.new(self)
    end

    def set_order(num)
      @order = num
    end

    # addons order
    #   100- meta
    #   200- main contents
    #   300- attributes
    #   400- sub contents
    #   500- settings
    #   600- system
    def order
      @order || 900
    end
end
