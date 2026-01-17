class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  def render_json(data, status: :ok)
    render json: camelize_keys(data), status: status
  end

  def camelize_keys(object)
    case object
    when Array
      object.map { |item| camelize_keys(item) }
    when Hash
      object.each_with_object({}) do |(k, v), h|
        new_key = k.to_s.camelize(:lower)
        h[new_key] = camelize_keys(v)
      end
    else
      object
    end
  end
end
