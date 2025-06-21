# miniere_sotterranee.rb
require 'securerandom'

# --- Classi base ---
class Personaggio
  attr_accessor :nome, :vita, :attacco, :difesa, :posizione

  def initialize(nome, vita, attacco, difesa)
    @nome = nome
    @vita = vita
    @attacco = attacco
    @difesa = difesa
    @posizione = [0, 0]
  end

  def vivo?
    @vita > 0
  end
end

class Nemico < Personaggio
  attr_accessor :tipo, :stordito
  def initialize(tipo, vita, attacco, difesa)
    super(tipo, vita, attacco, difesa)
    @tipo = tipo
    @stordito = 0
  end
end

class Boss < Personaggio
  def initialize
    super('Golem delle Profondità', 100, 18, 8)
  end
  def attacco_area(giocatore)
    puts "Il Golem scatena un attacco d'area!"
    danno = 15
    giocatore.vita -= danno
    puts "Borin subisce #{danno} danni dall'attacco d'area!"
  end
end

class Risorsa
  attr_accessor :tipo, :quantita
  def initialize(tipo, quantita)
    @tipo = tipo
    @quantita = quantita
  end
end

# --- Giocatore ---
class Giocatore < Personaggio
  attr_accessor :scossa_ricarica, :inventario

  def initialize
    super('Borin', 90, 14, 6)
    @scossa_ricarica = 0
    @inventario = Hash.new(0)
  end

  def scossa_tellurica(mappa, nemici)
    if @scossa_ricarica == 0
      puts "Borin usa SCOSSA TELLURICA!"
      # Distrugge pareti adiacenti e stordisce nemici nella stessa cella
      adiacenti = [[-1,0],[1,0],[0,-1],[0,1]]
      adiacenti.each do |dx, dy|
        x, y = @posizione[0] + dx, @posizione[1] + dy
        if mappa.area_valida?([x, y]) && mappa.griglia[x][y] == :parete
          mappa.griglia[x][y] = :vuoto
          puts "La parete a [#{x},#{y}] crolla!"
        end
      end
      nemici.each do |n|
        if n.posizione == @posizione && n.vivo?
          n.stordito = 2
          puts "#{n.nome} è stordito!"
        end
      end
      @scossa_ricarica = 4
    else
      puts "Scossa Tellurica non è pronta!"
    end
  end

  def turno_ricarica
    @scossa_ricarica -= 1 if @scossa_ricarica > 0
  end
end

# --- Mappa modulare ---
class Miniera
  attr_accessor :griglia, :nemici, :risorse, :tesori, :uscita, :boss, :timer_crollo, :allerta

  def initialize(dim = 6)
    @dim = dim
    @griglia = Array.new(dim) { Array.new(dim) { :parete } }
    @nemici = []
    @risorse = []
    @tesori = []
    @uscita = [dim-1, dim-1]
    @boss = nil
    @timer_crollo = 20
    @allerta = false
    genera_mappa
  end

  def genera_mappa
    # Crea tunnel random
    x, y = 0, 0
    @griglia[x][y] = :vuoto
    15.times do
      dir = [[-1,0],[1,0],[0,-1],[0,1]].sample
      nx, ny = x + dir[0], y + dir[1]
      if area_valida?([nx, ny])
        @griglia[nx][ny] = :vuoto
        x, y = nx, ny
      end
    end
    # Uscita
    @griglia[@uscita[0]][@uscita[1]] = :vuoto
    # Pareti distruttibili
    8.times do
      x, y = SecureRandom.random_number(@dim), SecureRandom.random_number(@dim)
      @griglia[x][y] = :distruttibile if @griglia[x][y] == :parete
    end
    # Nemici
    3.times do
      x, y = SecureRandom.random_number(@dim), SecureRandom.random_number(@dim)
      next unless @griglia[x][y] == :vuoto
      tipo = SecureRandom.random_number < 0.5 ? 'Troll di Pietra' : 'Pipistrello Gigante'
      n = Nemico.new(tipo, tipo == 'Troll di Pietra' ? 30 : 18, tipo == 'Troll di Pietra' ? 10 : 7, tipo == 'Troll di Pietra' ? 4 : 2)
      n.posizione = [x, y]
      @nemici << n
    end
    # Tesori
    2.times do
      x, y = SecureRandom.random_number(@dim), SecureRandom.random_number(@dim)
      @tesori << {pos: [x, y], trovato: false} if @griglia[x][y] == :vuoto
    end
    # Risorse
    3.times do
      x, y = SecureRandom.random_number(@dim), SecureRandom.random_number(@dim)
      @risorse << {pos: [x, y], oggetto: Risorsa.new(:minerale, 1)} if @griglia[x][y] == :vuoto
    end
    # Boss
    @boss = Boss.new
    @boss.posizione = [@dim/2, @dim/2]
    @griglia[@boss.posizione[0]][@boss.posizione[1]] = :vuoto
  end

  def area_valida?(pos)
    pos.all? { |v| v.between?(0, @dim-1) }
  end

  def descrivi_area(pos)
    cella = @griglia[pos[0]][pos[1]]
    puts "\nTi trovi in una zona: #{cella.to_s}"
    nemici_presenti = @nemici.select { |n| n.posizione == pos && n.vivo? }
    puts "Nemici: #{nemici_presenti.any? ? nemici_presenti.map(&:nome).join(', ') : 'Nessuno'}"
    puts "Boss: QUI!" if pos == @boss.posizione && @boss.vivo?
    tesoro = @tesori.find { |t| t[:pos] == pos && !t[:trovato] }
    puts "Tesoro: QUI!" if tesoro
    risorsa = @risorse.find { |r| r[:pos] == pos }
    puts "Risorsa: #{risorsa ? risorsa[:oggetto].tipo.to_s : 'Nessuna'}"
    puts "Uscita: QUI!" if pos == @uscita
    puts "ALLERTA CROLLO!" if @allerta
    puts "Timer crollo: #{@timer_crollo}"
  end
end

# --- Gioco principale ---
giocatore = Giocatore.new
miniera = Miniera.new(6)
giocatore.posizione = [0, 0]

puts "Sei Borin, il nano. Esplora le miniere, trova tesori e sconfiggi il Golem delle Profondità!"

loop do
  miniera.descrivi_area(giocatore.posizione)
  puts "\nVita: #{giocatore.vita} | Posizione: #{giocatore.posizione.inspect} | Inventario: #{giocatore.inventario}"
  
  azioni_possibili = []
  
  # Azione: Muoviti
  azioni_possibili << { testo: "Muoviti (nord/sud/est/ovest)", azione: -> {
    puts "Dove vuoi andare? (n/s/e/o)"; dir = gets.chomp
    dx, dy = case dir; when 'n' then [-1, 0]; when 's' then [1, 0]; when 'e' then [0, 1]; when 'o' then [0, -1]; else [0, 0]; end
    nuova_pos = [giocatore.posizione[0] + dx, giocatore.posizione[1] + dy]
    if miniera.area_valida?(nuova_pos) && [:vuoto, :distruttibile].include?(miniera.griglia[nuova_pos[0]][nuova_pos[1]])
      giocatore.posizione = nuova_pos; puts "Ti muovi a #{giocatore.posizione.inspect}"
    else
      puts "Non puoi andare lì."
    end
  }}
  
  # Azione: Scava
  azioni_possibili << { testo: "Scava parete adiacente", azione: -> {
    puts "Scegli direzione per scavare (n/s/e/o)"; dir = gets.chomp
    dx, dy = case dir; when 'n' then [-1, 0]; when 's' then [1, 0]; when 'e' then [0, 1]; when 'o' then [0, -1]; else [0, 0]; end
    target = [giocatore.posizione[0] + dx, giocatore.posizione[1] + dy]
    if miniera.area_valida?(target) && miniera.griglia[target[0]][target[1]] == :distruttibile
      miniera.griglia[target[0]][target[1]] = :vuoto; puts "Hai scavato un tunnel verso #{target.inspect}!"
    else
      puts "Non puoi scavare lì."
    end
  }}

  # Azione: Scossa Tellurica
  if giocatore.scossa_ricarica == 0
    azioni_possibili << { testo: "Usa Scossa Tellurica", azione: -> { giocatore.scossa_tellurica(miniera, miniera.nemici) }}
  end

  # Azione: Raccogli risorsa
  if miniera.risorse.any? { |r| r[:pos] == giocatore.posizione }
    azioni_possibili << { testo: "Raccogli risorsa", azione: -> {
      risorsa = miniera.risorse.find { |r| r[:pos] == giocatore.posizione }
      giocatore.inventario[risorsa[:oggetto].tipo] += risorsa[:oggetto].quantita
      puts "Hai raccolto #{risorsa[:oggetto].tipo}!"; miniera.risorse.delete(risorsa)
    }}
  end

  # Azione: Apri tesoro
  if miniera.tesori.any? { |t| t[:pos] == giocatore.posizione && !t[:trovato] }
     azioni_possibili << { testo: "Apri tesoro", azione: -> {
       tesoro = miniera.tesori.find { |t| t[:pos] == giocatore.posizione }; tesoro[:trovato] = true
       giocatore.inventario[:minerale] += 2; puts "Hai trovato un tesoro! Ottieni 2 minerali."
     }}
  end
  
  # Azioni di combattimento
  miniera.nemici.select { |n| n.posizione == giocatore.posizione && n.vivo? }.each do |n|
    azioni_possibili << { testo: "Combatti #{n.nome}", azione: -> {
      danno = [giocatore.attacco - n.difesa, 1].max * (n.stordito > 0 ? 2 : 1)
      puts "Colpisci #{n.nome} per #{danno} danni.#{n.stordito > 0 ? ' (Critico su stordito!)' : ''}"
      n.vita -= danno
    }}
  end
  
  # Azione: Combatti Boss
  if miniera.boss&.posizione == giocatore.posizione && miniera.boss.vivo?
    azioni_possibili << { testo: "Combatti il BOSS: #{miniera.boss.nome}", azione: -> {
      # ... logica combattimento boss semplificata ...
      boss = miniera.boss
      danno = [giocatore.attacco - boss.difesa, 1].max
      puts "Colpisci il Golem per #{danno} danni."; boss.vita -= danno
      if boss.vivo?
        if SecureRandom.random_number < 0.4
          boss.attacco_area(giocatore)
        else
          danno_boss = [boss.attacco - giocatore.difesa, 1].max
          puts "Il Golem ti colpisce per #{danno_boss} danni."; giocatore.vita -= danno_boss
        end
      else
        puts "Hai sconfitto il Golem delle Profondità!"
      end
    }}
  end

  # Azione: Esci
  if giocatore.posizione == miniera.uscita && miniera.boss && !miniera.boss.vivo?
    azioni_possibili << { testo: "Esci dalla miniera", azione: -> {
      puts "Hai lasciato le miniere con i tesori! Vittoria!"; exit
    }}
  end

  puts "\nAzioni disponibili:"
  azioni_possibili.each_with_index { |a, i| puts "#{i+1}. #{a[:testo]}" }
  scelta = gets.chomp.to_i - 1

  if scelta >= 0 && scelta < azioni_possibili.length
      azioni_possibili[scelta][:azione].call
  else
      puts "Azione non valida."
  end

  # Timer crollo
  miniera.timer_crollo -= 1
  if miniera.timer_crollo <= 5 && !miniera.allerta
    miniera.allerta = true
    puts "\n*** ALLERTA: Rischio crollo imminente! ***"
  end
  if miniera.timer_crollo == 0
    puts "\nLe miniere crollano! Borin viene travolto... Game Over."
    break
  end

  # Turno nemici
  miniera.nemici.each do |n|
    next unless n.vivo?
    if n.posizione == giocatore.posizione && n.stordito == 0
      danno = [n.attacco - giocatore.difesa, 1].max
      puts "#{n.nome} ti attacca per #{danno} danni!"
      giocatore.vita -= danno
    elsif n.stordito > 0
      n.stordito -= 1
    end
  end
  giocatore.turno_ricarica
  if giocatore.vita <= 0
    puts "Borin è stato sconfitto nelle miniere... Game Over."
    break
  end
end 