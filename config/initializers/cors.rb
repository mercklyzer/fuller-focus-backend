Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Allow requests from localhost on any port (for development)
    origins 'localhost:3000', 'localhost:3001', 'localhost:8080', 'localhost:4200', '127.0.0.1:3000', '127.0.0.1:3001', '127.0.0.1:8080', '127.0.0.1:4200'

    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true
  end

  # For production, be more specific about allowed origins
  if Rails.env.production?
    allow do
      origins 'https://yourdomain.com', 'https://www.yourdomain.com'

      resource '*',
        headers: :any,
        methods: [:get, :post, :put, :patch, :delete, :options, :head],
        credentials: true
    end
  end
end
