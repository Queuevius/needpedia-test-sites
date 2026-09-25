# Demo content for Needpedia test-site copies. Idempotent: safe to re-run.
# Creates login-ready users, one group, task cards, and a subject->problem->idea chain.

PASSWORD = 'DemoPass!2026'

USER_DEFS = [
  { email: 'demo.founder@example.test', first_name: 'Demo', last_name: 'Founder', admin: true },
  { email: 'demo.dev@example.test',     first_name: 'Demo', last_name: 'Dev',     admin: false },
  { email: 'demo.builder@example.test', first_name: 'Demo', last_name: 'Builder', admin: false },
]

def ensure_user(attrs)
  user = User.find_or_initialize_by(email: attrs[:email])
  user.assign_attributes(
    first_name: attrs[:first_name],
    last_name: attrs[:last_name],
    admin: attrs[:admin],
    approved: true,
    confirmed_at: Time.current,
    password: PASSWORD,
    password_confirmation: PASSWORD
  )
  user.skip_confirmation_notification! if user.new_record?
  user.save!
  user
end

users = USER_DEFS.map { |attrs| ensure_user(attrs) }
admin = users.first

group = Group.find_or_create_by!(name: 'Demo Group') do |g|
  g.user = admin
end

users.each do |u|
  Membership.find_or_create_by!(user: u, group: group)
end

def ensure_task(title, group, user, description)
  task = Task.find_or_initialize_by(title: title, group: group)
  task.assign_attributes(
    user: user,
    description: description,
    status: 'Available Tasks',
    priority: 'Casual',
    hours: 2,
    skills: ['testing', 'demo']
  )
  task.save!
  task
end

ensure_task('Confirm the demo copy loads', group, users[1], 'Open the home page and log in to confirm the copy works.')
ensure_task('Add a task card', group, users[2], 'Create one new task card under Demo Group.')
ensure_task('Invite a tester', group, admin, 'Invite someone and confirm the invite flow.')

subject = Post.find_or_initialize_by(title: 'Demo Subject: Clean water in Onitsha', post_type: Post::POST_TYPE_SUBJECT)
subject.user = admin
subject.save!

problem = Post.find_or_initialize_by(title: 'Demo Problem: Street flooding during heavy rain', post_type: Post::POST_TYPE_PROBLEM)
problem.user = users[1]
problem.subject_id = subject.id
problem.save!

idea = Post.find_or_initialize_by(title: 'Demo Idea: Rain barrels and a drainage cooperative', post_type: Post::POST_TYPE_IDEA)
idea.user = users[2]
idea.subject_id = subject.id
idea.problem_id = problem.id
idea.save!

puts 'Demo content ready.'
puts "Logins (password: #{PASSWORD}):"
USER_DEFS.each { |u| puts "  #{u[:email]}  admin=#{u[:admin]}" }
