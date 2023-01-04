class Anchormodel
  module Version
    MAJOR = 0
    MINOR = 0
    PATCH = 3

    EDGE = true

    LABEL = [MAJOR, MINOR, PATCH, EDGE ? 'edge' : nil].compact.join('.')
  end
end
