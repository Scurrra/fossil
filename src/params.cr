module Fossil::Param
  alias PathParamType = Int32 | UUID | String

  enum PathParamTypeEnum
    Int
    UUID
    String
  end

  annotation Path; end
  annotation Query; end
  annotation Form; end
  annotation File; end
end
