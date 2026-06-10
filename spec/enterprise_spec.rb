# frozen_string_literal: true

RSpec.describe 'RBAC via Ability' do
  let(:account) { create(:account) }

  context 'Admin' do
    let(:user) { create(:user, account:, role: :admin) }
    subject    { Ability.new(user) }

    it { is_expected.to be_able_to(:manage, Template.new(account:)) }
    it { is_expected.to be_able_to(:manage, User.new(account:)) }
    it { is_expected.not_to be_able_to(:destroy, AuditLog.new(account:)) }
  end

  context 'Editor' do
    let(:user) { create(:user, account:, role: :editor) }
    subject    { Ability.new(user) }

    it { is_expected.to     be_able_to(:create, Template.new(account:)) }
    it { is_expected.not_to be_able_to(:manage, User.new(account:)) }
    it { is_expected.not_to be_able_to(:read,   AuditLog.new(account:)) }
  end

  context 'Viewer' do
    let(:user) { create(:user, account:, role: :viewer) }
    subject    { Ability.new(user) }

    it { is_expected.to     be_able_to(:read,   Template.new(account:)) }
    it { is_expected.not_to be_able_to(:create, Template) }
    it { is_expected.not_to be_able_to(:update, Submission.new(account:)) }
  end
end

RSpec.describe AuditLog do
  let(:account) { create(:account) }

  it 'records successfully' do
    log = described_class.record!(account:, action: 'test_action')
    expect(log).to be_persisted
  end

  it 'is immutable' do
    log = create(:audit_log, account:)
    expect { log.update!(action: 'changed') }.to raise_error(ActiveRecord::ReadOnlyRecord)
    expect { log.destroy! }.to             raise_error(ActiveRecord::ReadOnlyRecord)
  end

  it 'swallows errors gracefully' do
    allow(described_class).to receive(:create!).and_raise(ActiveRecord::StatementInvalid)
    expect { described_class.record!(account:, action: 'x') }.not_to raise_error
  end
end

RSpec.describe SignatureReminderJob do
  let(:account)    { create(:account, reminders_enabled: true, reminder_interval_days: 1, reminder_max_count: 3) }
  let(:submission) { create(:submission, account:, completed_at: nil, created_at: 2.days.ago) }
  let!(:submitter) { create(:submitter, submission:, email: 'signer@example.com', completed_at: nil) }

  it 'sends reminder for overdue submitter' do
    expect(SignatureReminderMailer).to receive(:remind).and_return(double(deliver_now: true))
    described_class.new.perform
    expect(ReminderLog.count).to eq(1)
  end

  it 'skips completed submissions' do
    submission.update!(completed_at: Time.current)
    expect(SignatureReminderMailer).not_to receive(:remind)
    described_class.new.perform
  end

  it 'skips when max reminders reached' do
    3.times { |i| create(:reminder_log, submission:, email: submitter.email, status: 'sent', sent_at: (3 - i).days.ago) }
    expect(SignatureReminderMailer).not_to receive(:remind)
    described_class.new.perform
  end
end
