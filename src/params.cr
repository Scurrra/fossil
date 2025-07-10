module Fossil::Param
  alias PathParamType = Int | UUID | String

  enum PathParamTypeEnum
    Int
    UUID
    String
  end

  annotation Path; end
  annotation Query; end
  annotation Form; end
  annotation File; end

  class Value(T)
    @name : String
    @value : T

    def initialize(@name, @value)
    end
  end
end
