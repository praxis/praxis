
class BulkResponse < Praxis::Response
  self.response_name = :bulk_response

  def handle
    @status = 200
  end

end

