
class MultipartResponse < Praxis::Response
  self.response_name = :multipart

  def handle
    @status = 200
  end

end

