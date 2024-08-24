# frozen_string_literal: true

module IdentitiesHelper
  def autocomplete_hash(id)
    { label: id.autocomplete, value: id.name }
  end
end
