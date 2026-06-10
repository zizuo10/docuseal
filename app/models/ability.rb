# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    return unless user.present?

    case user.role.to_sym
    when :admin  then admin_permissions(user)
    when :editor then editor_permissions(user)
    when :viewer then viewer_permissions(user)
    end

    can :read,   User, id: user.id
    can :update, User, id: user.id
  end

  private

  def admin_permissions(user)
    account_id = user.account_id
    can :manage, Template,       account_id: account_id
    can :manage, Submission,     account_id: account_id
    can :manage, Submitter,      account_id: account_id
    can :manage, Account,        id: account_id
    can :manage, AccountConfig,  account_id: account_id
    can :manage, AccessToken,    account_id: account_id
    can :manage, WebhookUrl,     account_id: account_id
    can :manage, EncryptedConfig, account_id: account_id
    can :manage, User,           account_id: account_id
    can    :read,    AuditLog,   account_id: account_id
    cannot :destroy, AuditLog
    cannot :update,  AuditLog
    can :read, ReminderLog
  end

  def editor_permissions(user)
    account_id = user.account_id
    can %i[read create update], Template,   account_id: account_id
    can :read,                  Submission, account_id: account_id
    can :create,                Submission, account_id: account_id
    can %i[read create update], Submitter,  account_id: account_id
    can :read, AccountConfig, account_id: account_id
    can :read, Account,       id: account_id
    cannot :manage, AccessToken
    cannot :manage, WebhookUrl
    cannot :manage, EncryptedConfig
    cannot :read,   AuditLog
  end

  def viewer_permissions(user)
    account_id = user.account_id
    can :read, Template,   account_id: account_id
    can :read, Submission, account_id: account_id
    can :read, Submitter,  account_id: account_id
    can :read, Account,    id: account_id
    cannot :create,  :all
    cannot :update,  :all
    cannot :destroy, :all
    cannot :manage,  :all
  end
end
