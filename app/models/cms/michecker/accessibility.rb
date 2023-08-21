class Cms::Michecker::Accessibility
  include ActiveModel::Model
  include Cms::Michecker::Base

  def enum_csv(options)
    drawer = SS::Csv.draw(:export, context: self) do |drawer|
      # レベル
      drawer.column :severity
      # レベル（文字列）
      drawer.column :severityStr
      # 知覚可能
      drawer.column :evaluationItem_tableDataMetrics0 do
        drawer.body { |item| item.evaluationItem["tableDataMetrics"].try { |array| array[0] } }
      end
      # 操作可能
      drawer.column :evaluationItem_tableDataMetrics1 do
        drawer.body { |item| item.evaluationItem["tableDataMetrics"].try { |array| array[1] } }
      end
      # 理解可能
      drawer.column :evaluationItem_tableDataMetrics2 do
        drawer.body { |item| item.evaluationItem["tableDataMetrics"].try { |array| array[2] } }
      end
      # 堅牢
      drawer.column :evaluationItem_tableDataMetrics3 do
        drawer.body { |item| item.evaluationItem["tableDataMetrics"].try { |array| array[3] } }
      end
      # WCAG 2.0
      drawer.column :evaluationItem_tableDataGuideline0 do
        drawer.body { |item| item.evaluationItem["tableDataGuideline"].try { |array| array[0] } }
      end
      # Section508
      drawer.column :evaluationItem_tableDataGuideline1 do
        drawer.body { |item| item.evaluationItem["tableDataGuideline"].try { |array| array[1] } }
      end
      # JIS
      drawer.column :evaluationItem_tableDataGuideline2 do
        drawer.body { |item| item.evaluationItem["tableDataGuideline"].try { |array| array[2] } }
      end
      # 達成方法
      drawer.column :evaluationItem_tableDataTechniques do
        drawer.body { |item| item.evaluationItem["tableDataTechniques"] }
      end
      # 内容
      drawer.column :description
    end

    drawer.enum(self.items, options.reverse_merge(model: self.class))
  end
end
