# Unreleased

- Add boolean accessor directly to all anchormodels
- Add ActiveRecord::Enum style readers, writers and scopes to the model
- Attribute#anchor_class is now called `anchormodel_class`.

# 0.1.0 (18.01.2023)

- Remove `Anchormodels::` prefix and have anchormodels in the root namespace instead.
- Add basic testing

# 0.0.2 (30.12.2022)

- Fix a bug where `.all` loaded entries from all classes.

# 0.0.1 (17.12.2022)

- Initial release, MVP, early stage. Do not use.