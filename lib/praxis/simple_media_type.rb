module Praxis
  
  SimpleMediaType = Struct.new(:identifier) do
    def ===(other_thing)
      identifier == other_thing
    end

    def describe
      'todo' # TODO: replace todo
    end
  end

end
