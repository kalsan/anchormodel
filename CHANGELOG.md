# 0.2.3 (01.11.2024)

- Relax Rails dependency

# 0.2.2 (14.08.2024)

- Allow passing `anchormodel_attribute` explicitely to `anchormodel` input and enhance error message
- In `anchormodel` input, fallback to searching selected value in input html options as well
- Update ruby version to 3.2.2

# 0.2.1 (22.05.2024)

- Stop enforcing include_blank for SimpleForm, due to https://github.com/heartcombo/simple_form/issues/1427

# 0.2.0 (27.04.2024)

- Add support for multiple anchormodels (`belongs_to_anchormodels`)
- Implement YourAnchormodelclass.form_collection

# 0.1.5 (24.04.2024)

- Enhance documentation
- Add support for simple_form

# 0.1.4 (23.04.2024)

- Stick closer to the Rails API of Value
- Enhance testing

# 0.1.3 (19.05.2023)

- Add Rails generator

# 0.1.2 (25.01.2023)

- Consider empty string as nil (this is necessary to make Rails assignments work)

# 0.1.1 (24.01.2023)

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