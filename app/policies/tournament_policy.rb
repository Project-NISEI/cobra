# frozen_string_literal: true

class TournamentPolicy < ApplicationPolicy
  def show?
    !record.private? || record.user == user
  end

  def create?
    user
  end

  def update?
    user && record.user == user
  end

  def destroy?
    update?
  end

  def upload_to_abr?
    update?
  end

  def register?
    record.self_registration || update?
  end

  def self_report?
    record.allow_self_reporting
  end

  def save_json?
    show?
  end

  def cut?
    update?
  end

  def my?
    user
  end

  def new_demo?
    Flipper.enabled?(:demo_tournaments, user)
  end

  def new_demo_form?
    Flipper.enabled?(:demo_tournaments, user)
  end

  def create_demo?
    Flipper.enabled?(:demo_tournaments, user)
  end
end
