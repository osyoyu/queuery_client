module QueueryClient
  class Client
    def initialize(options = {})
      @options = options
    end

    def execute_query(select_stmt, values)
      garage_client.post("/v1/queries", q: select_stmt, values: values)
    end

    def get_query(id)
      garage_client.get("/v1/queries/#{id}", fields: '__default__,s3_prefix')
    end

    def wait_for(id)
      loop do
        query = get_query(id)
        case query.status
        when 'success', 'failed'
          return query
        end
        sleep 3
      end
    end

    def query_and_wait(select_stmt, values)
      query = execute_query(select_stmt, values)
      wait_for(query.id)
    end

    def query(select_stmt, values)
      query = query_and_wait(select_stmt, values)
      case query.status
      when 'success'
        UrlDataFileBundle.new(
          query.data_file_urls,
          s3_prefix: query.s3_prefix,
        )
      when 'failed'
        raise QueryError.new(query.error)
      end
    end

    def garage_client
      @garage_client ||= BasicAuthGarageClient.new(
        endpoint: options.endpoint,
        path_prefix: '/',
        login: options.token,
        password: options.token_secret
      )
    end

    def options
      default_options.merge(@options)
    end

    def default_options
      QueueryClient.configuration
    end
  end
end
