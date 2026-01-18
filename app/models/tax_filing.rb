class TaxFiling < ApplicationRecord
  scope :search_name, ->(name) { where("business_name LIKE ?", "%#{name}%") if name.present? }

  validates :ein, uniqueness: { scope: :tax_year }

  def revenue_delta_amount
    total_revenue - (py_total_revenue || 0)
  end

  def revenue_delta_percent
    return 0 if py_total_revenue.nil?
    ((total_revenue - py_total_revenue) / py_total_revenue * 100).round(2)
  end

  def expenses_delta_amount
    total_expenses - (py_total_expenses || 0)
  end

  def expenses_delta_percent
    return 0 if py_total_expenses.nil?
    ((total_expenses - py_total_expenses) / py_total_expenses * 100).round(2)
  end

  def assets_delta_amount
    total_assets - (py_total_assets || 0)
  end

  def assets_delta_percent
    return 0 if py_total_assets.nil?
    ((total_assets - py_total_assets) / py_total_assets * 100).round(2)
  end

  def employees_delta_amount
    (employee_count || 0) - (py_employee_count || 0)
  end

  def employees_delta_percent
    return 0 if py_employee_count.nil?
    (((employee_count || 0) - (py_employee_count || 0)).to_f / (py_employee_count || 1) * 100).round(2)
  end

  def as_json(options = {})
    super(options).tap do |hash|
      # convert all BigDecimal fields to float
      self.class.columns.select { |c| c.type == :decimal }.each do |col|
        key = col.name
        hash[key] = hash[key].to_f if hash[key]
      end
    end
  end
end
