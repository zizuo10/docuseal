# frozen_string_literal: true

# Include in User model: include UserRoles
module UserRoles
  extend ActiveSupport::Concern

  included do
    enum role: { admin: 0, editor: 1, viewer: 2 }, _prefix: true
    validates :role, presence: true
    scope :admins,  -> { where(role: :admin) }
    scope :editors, -> { where(role: :editor) }
    scope :viewers, -> { where(role: :viewer) }
  end

  def can_manage_users?    = role_admin?
  def can_create_documents? = role_admin? || role_editor?
  def read_only?            = role_viewer?
  def sidekiq?              = role_admin?   # replaces any existing sidekiq? check
  def role_label            = role.capitalize
end
