# frozen_string_literal: true

class HomeController < ApplicationController
  def home
    authorize Tournament, :index?

    @tournaments = Tournament.includes(:user).where(date: Date.current, private: false)
  end

  def help
    skip_authorization
  end
end
