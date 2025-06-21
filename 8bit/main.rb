# main.rb
puts "Benvenuto nell'Avventura 8-bit! Scegli uno scenario:\n"
puts "1. Castello in rovina (Ardyn)"
puts "2. Foresta maledetta (Lyra)"
puts "3. Miniere sotterranee (Borin)"
puts "4. Rovine magiche (Elandor)"
print "Scelta: "
scelta = gets.chomp

case scelta
when '1'
  require_relative 'castle_quest'
when '2'
  require_relative 'foresta_maledetta'
when '3'
  require_relative 'miniere_sotterranee'
when '4'
  require_relative 'rovine_magiche'
else
  puts "Scelta non valida."
end 