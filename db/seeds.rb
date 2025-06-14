puts "🌱 Seeding tasks..."

user = User.first || User.create!(email: "test@example.com", password: "password")

puts "Creating task 1"
Task.create!(title: "買い物に行く", user: user, is_done: :not_started)

puts "Creating task 2"
Task.create!(title: "レポートを書く", user: user, is_done: :not_started)

puts "Creating task 3"
Task.create!(title: "本を読む", user: user, is_done: :closed)

puts "✅ Done!"
