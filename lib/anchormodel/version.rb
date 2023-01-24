class Anchormodel
  module Version
    MAJOR = 0
    MINOR = 1
    PATCH = 1

    EDGE = false

    LABEL = [MAJOR, MINOR, PATCH, EDGE ? 'edge' : nil].compact.join('.')
  end
end
