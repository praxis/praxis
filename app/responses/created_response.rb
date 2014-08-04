
class CreatedResponse < Praxis::Response
  self.response_name = :created

  def handle
    @status = 201
  end

end
