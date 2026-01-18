class TaxFilingsController < ApplicationController
  def index
    tax_filings = TaxFiling.paginate(page: params[:page] || 1, per_page: 10).search_name(params[:q])

    returned_tax_filings = tax_filings.map do |filing|
      filing.as_json.merge({
        # need to convert to float as big decimals are returned as strings in JSON in Rails
        revenue_delta_amount: filing.revenue_delta_amount.to_f,
        revenue_delta_percent: filing.revenue_delta_percent.to_f,
        expenses_delta_amount: filing.expenses_delta_amount.to_f,
        expenses_delta_percent: filing.expenses_delta_percent.to_f,
        assets_delta_amount: filing.assets_delta_amount.to_f,
        assets_delta_percent: filing.assets_delta_percent.to_f,
        employees_delta_amount: filing.employees_delta_amount.to_f,
        employees_delta_percent: filing.employees_delta_percent.to_f
      })
    end

    render_json({
      data: {
        tax_filings: returned_tax_filings,
      },
      meta: {
        total_count: tax_filings.total_entries,
        page: params[:page].to_i || 1,
        total_pages: tax_filings.total_pages
      }
    })
  end

  def show
    # Assumption: There can be multiple tax filings under the same EIN for different years.
    tax_filings = TaxFiling.where(ein: params[:id]).order(tax_year: :desc)

    if tax_filings.empty?
      render_json({ error: "Company does not exist." }, status: :not_found)
      return
    end

    returned_tax_filings = tax_filings.map do |filing|
      filing.as_json.merge({
        # need to convert to float as big decimals are returned as strings in JSON in Rails
        revenue_delta_amount: filing.revenue_delta_amount.to_f,
        revenue_delta_percent: filing.revenue_delta_percent.to_f,
        expenses_delta_amount: filing.expenses_delta_amount.to_f,
        expenses_delta_percent: filing.expenses_delta_percent.to_f,
        assets_delta_amount: filing.assets_delta_amount.to_f,
        assets_delta_percent: filing.assets_delta_percent.to_f,
        employees_delta_amount: filing.employees_delta_amount.to_f,
        employees_delta_percent: filing.employees_delta_percent.to_f

        # I decided to not display additional fields such as
        # key personnel full names, and their titles,
        # expenses by category,
        # revenue vs expense trend
        # and staffing signal
        # due to lack of time.
      })
    end

    render_json({
      data: {
        tax_filings: returned_tax_filings
      }
    })
  end
end
