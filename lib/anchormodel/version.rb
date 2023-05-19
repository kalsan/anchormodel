class Anchormodel
  module Version
    MAJOR = 0
    MINOR = 1
    PATCH = 4

    EDGE = true

    LABEL = [MAJOR, MINOR, PATCH, EDGE ? 'edge' : nil].compact.join('.')
  end
end
