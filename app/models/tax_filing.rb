class TaxFiling < ApplicationRecord
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
    employee_count - (py_employee_count || 0)
  end

  def employees_delta_percent
    return 0 if py_employee_count.nil?
    ((employee_count - py_employee_count).to_f / py_employee_count * 100).round(2)
  end
end
