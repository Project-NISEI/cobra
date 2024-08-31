# frozen_string_literal: true

module Pairable
  extend ActiveSupport::Concern

  def unpairable_opponents
    @unpairable_opponents ||= opponents.map { |p| p.id ? p : SwissImplementation::Bye }
  end
end
