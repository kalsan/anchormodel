class Animal < Anchormodel
  new :cat
  new :dog
  new :horse
  new :rat
  new :big_cat # key with `_` — used to verify LIKE wildcard escaping
end
