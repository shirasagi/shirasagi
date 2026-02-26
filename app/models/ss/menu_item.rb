module SS
  MenuItem = Data.define(:label, :path_proc, :css_classes) do
    def initialize(label:, path_proc:, css_classes: nil)
      super
    end

    def path(*args, **kwargs)
      path_proc.call(*args, **kwargs)
    end
  end
end
