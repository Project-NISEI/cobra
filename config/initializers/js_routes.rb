# frozen_string_literal: true

JsRoutes.setup do |c|
  # Setup your JS module system:
  # ESM, CJS, AMD, UMD or nil
  # c.module_type = "ESM"
  # Sprockets integration uses nil and creates a global variable in JS from the namespace value
  c.module_type = nil
  c.namespace = 'Routes'
end
