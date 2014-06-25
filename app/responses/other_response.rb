class OtherResponse < Praxis::Response
  self.response_name = :other_response

  def handle
    @status = 200
  end

end

