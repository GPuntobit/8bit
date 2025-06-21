# foresta_maledetta.rb
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
  attr_accessor :percezione, :ombra

  def initialize(nome, vita, attacco, difesa, percezione)
    super(nome, vita, attacco, difesa)
    @percezione = percezione # raggio di vista
    @ombra = false
  end

  def vede?(giocatore, mappa, nebbia)
    return false if giocatore.in_ombra?(mappa, nebbia)
    distanza = (giocatore.posizione[0] - @posizione[0]).abs + (giocatore.posizione[1] - @posizione[1]).abs
    distanza <= @percezione
  end
end

class Proiettile
  attr_accessor :tipo, :danno
  def initialize(tipo, danno)
    @tipo = tipo
    @danno = danno
  end
end

class Puzzle
  attr_accessor :tipo, :risolto
  def initialize(tipo)
    @tipo = tipo
    @risolto = false
  end

  def tenta_risoluzione(azione)
    if @tipo == :sposta_rocce && azione == :sposta
      @risolto = true
      puts "Hai spostato la roccia!"
    elsif @tipo == :colpisci_interruttore && azione == :freccia
      @risolto = true
      puts "Hai colpito l'interruttore con una freccia!"
    else
      puts "Non succede nulla."
    end
  end
end

class Nebbia
  attr_accessor :intensita
  def initialize(intensita)
    @intensita = intensita # 0 = chiaro, 1 = denso
  end

  def copre?(posizione)
    @intensita > 0 && SecureRandom.random_number < 0.7
  end
end

# --- Giocatore ---
class Giocatore < Personaggio
  attr_accessor :tiro_multiplo_ricarica, :ombra

  def initialize
    super('Lyra', 80, 12, 4)
    @tiro_multiplo_ricarica = 0
    @ombra = true
  end

  def tiro_multiplo(nemici)
    if @tiro_multiplo_ricarica == 0
      puts "Lyra usa TIRO MULTIPLO!"
      nemici.each do |n|
        next unless n.vivo?
        danno = (@attacco * 0.8).to_i
        puts "Colpisci #{n.nome} per #{danno} danni."
        n.vita -= danno
      end
      @tiro_multiplo_ricarica = 3
    else
      puts "Tiro Multiplo non è pronto!"
    end
  end

  def turno_ricarica
    @tiro_multiplo_ricarica -= 1 if @tiro_multiplo_ricarica > 0
  end

  def in_ombra?(mappa, nebbia)
    cella = mappa[@posizione[0]][@posizione[1]]
    cella == :ombra || nebbia.copre?(@posizione)
  end
end

# --- Foresta dinamica ---
class Foresta
  attr_accessor :mappa, :nemici, :trappole, :puzzle, :nebbia, :uscita, :freccia_luce

  def initialize(dim = 5)
    @dim = dim
    @mappa = Array.new(dim) { Array.new(dim) { :erba } }
    @nemici = []
    @trappole = []
    @puzzle = []
    @nebbia = Nebbia.new(1)
    @uscita = [dim-1, dim-1]
    @freccia_luce = [SecureRandom.random_number(dim), SecureRandom.random_number(dim)]
    genera_elementi
  end

  def genera_elementi
    # Ombre random
    1.upto(@dim) do
      x, y = SecureRandom.random_number(@dim), SecureRandom.random_number(@dim)
      @mappa[x][y] = :ombra
    end
    # Nemici random
    3.times do
      x, y = SecureRandom.random_number(@dim), SecureRandom.random_number(@dim)
      n = Nemico.new('Spirito della Foresta', 20, 8, 2, 2)
      n.posizione = [x, y]
      @nemici << n
    end
    # Trappole random
    2.times do
      x, y = SecureRandom.random_number(@dim), SecureRandom.random_number(@dim)
      @trappole << {pos: [x, y], tipo: :liana}
    end
    # Puzzle
    @puzzle << {pos: [1, 2], oggetto: Puzzle.new(:sposta_rocce)}
    @puzzle << {pos: [3, 1], oggetto: Puzzle.new(:colpisci_interruttore)}
  end

  def descrivi_area(pos)
    cella = @mappa[pos[0]][pos[1]]
    puts "\nTi trovi in una zona di #{cella == :ombra ? 'ombra fitta' : 'erba e nebbia'}"
    puts "Nebbia: #{@nebbia.intensita > 0 ? 'Densa' : 'Leggera'}"
    nemici_presenti = @nemici.select { |n| n.posizione == pos && n.vivo? }
    puts "Nemici: #{nemici_presenti.any? ? nemici_presenti.map(&:nome).join(', ') : 'Nessuno'}"
    trappola = @trappole.find { |t| t[:pos] == pos }
    puts "Trappola: #{trappola ? trappola[:tipo].to_s : 'Nessuna'}"
    puzzle = @puzzle.find { |p| p[:pos] == pos && !p[:oggetto].risolto }
    puts "Enigma: #{puzzle ? puzzle[:oggetto].tipo.to_s : 'Nessuno'}"
    puts "Freccia di Luce: QUI!" if pos == @freccia_luce
    puts "Uscita: QUI!" if pos == @uscita
  end

  def area_valida?(pos)
    pos.all? { |v| v.between?(0, @dim-1) }
  end
end

# --- Gioco principale ---
giocatore = Giocatore.new
foresta = Foresta.new(5)
giocatore.posizione = [0, 0]

puts "Sei Lyra, l'arciere. Devi recuperare la Freccia di Luce nella foresta maledetta."

freccia_raccolta = false
loop do
  foresta.descrivi_area(giocatore.posizione)
  puts "\nVita: #{giocatore.vita} | Posizione: #{giocatore.posizione.inspect} | Ombra: #{giocatore.in_ombra?(foresta.mappa, foresta.nebbia) ? 'Sì' : 'No'}"
  
  azioni_possibili = []
  
  # Azione: Muoviti
  azioni_possibili << { testo: "Muoviti (nord/sud/est/ovest)", azione: -> {
    puts "Dove vuoi andare? (n/s/e/o)"
    dir = gets.chomp
    dx, dy = case dir
      when 'n' then [-1, 0]; when 's' then [1, 0]; when 'e' then [0, 1]; when 'o' then [0, -1]; else [0, 0]
    end
    nuova_pos = [giocatore.posizione[0] + dx, giocatore.posizione[1] + dy]
    if foresta.area_valida?(nuova_pos)
      giocatore.posizione = nuova_pos
      puts "Ti muovi a #{giocatore.posizione.inspect}"
      trappola = foresta.trappole.find { |t| t[:pos] == giocatore.posizione }
      if trappola
        puts "Sei finita in una trappola: #{trappola[:tipo]}! Subisci 8 danni."
        giocatore.vita -= 8
      end
    else
      puts "Non puoi andare lì."
    end
  }}

  nemici_presenti = foresta.nemici.select { |n| n.posizione == giocatore.posizione && n.vivo? }
  # Azione: Tiro Multiplo
  if nemici_presenti.any? && giocatore.tiro_multiplo_ricarica == 0
    azioni_possibili << { testo: "Usa Tiro Multiplo", azione: -> { giocatore.tiro_multiplo(nemici_presenti) }}
  end
  # Azione: Attacco normale
  nemici_presenti.each do |n|
    azioni_possibili << { testo: "Attacca #{n.nome}", azione: -> {
      danno = [giocatore.attacco - n.difesa, 1].max
      puts "Colpisci #{n.nome} per #{danno} danni."
      n.vita -= danno
    }}
  end
  
  puzzle = foresta.puzzle.find { |p| p[:pos] == giocatore.posizione && !p[:oggetto].risolto }
  # Azione: Risolvi enigma
  if puzzle
    azioni_possibili << { testo: "Risolvi enigma (#{puzzle[:oggetto].tipo})", azione: -> {
      if puzzle[:oggetto].tipo == :sposta_rocce
        puts "Vuoi spostare la roccia? (s/n)"; risp = gets.chomp
        puzzle[:oggetto].tenta_risoluzione(:sposta) if risp == 's'
      elsif puzzle[:oggetto].tipo == :colpisci_interruttore
        puts "Vuoi colpire l'interruttore? (s/n)"; risp = gets.chomp
        puzzle[:oggetto].tenta_risoluzione(:freccia) if risp == 's'
      end
    }}
  end
  
  # Azione: Raccogli Freccia di Luce
  if giocatore.posizione == foresta.freccia_luce && !freccia_raccolta
    azioni_possibili << { testo: "Raccogli la Freccia di Luce", azione: -> {
      puts "Hai raccolto la Freccia di Luce!"; freccia_raccolta = true
    }}
  end

  # Azione: Esci dalla foresta
  if giocatore.posizione == foresta.uscita && freccia_raccolta
    azioni_possibili << { testo: "Esci dalla foresta", azione: -> {
      puts "Hai lasciato la foresta maledetta con la Freccia di Luce. Vittoria!"; exit
    }}
  end
  
  puts "\nAzioni disponibili:"
  azioni_possibili.each_with_index { |a, i| puts "#{i+1}. #{a[:testo]}"}
  scelta = gets.chomp.to_i - 1

  if scelta >= 0 && scelta < azioni_possibili.length
    # La gestione di freccia_raccolta deve essere al di fuori della lambda per persistere
    if azioni_possibili[scelta][:testo] == "Raccogli la Freccia di Luce"
       puts "Hai raccolto la Freccia di Luce!"; freccia_raccolta = true
    elsif azioni_possibili[scelta][:testo] == "Esci dalla foresta"
        puts "Hai lasciato la foresta maledetta con la Freccia di Luce. Vittoria!"; break
    else
        azioni_possibili[scelta][:azione].call
    end
  else
    puts "Azione non valida."
  end

  # Turno nemici
  foresta.nemici.each do |n|
    next unless n.vivo?
    if n.posizione == giocatore.posizione && n.vede?(giocatore, foresta.mappa, foresta.nebbia)
      danno = [n.attacco - giocatore.difesa, 1].max
      puts "#{n.nome} ti attacca dall'ombra per #{danno} danni!"
      giocatore.vita -= danno
    end
  end
  giocatore.turno_ricarica
  if giocatore.vita <= 0
    puts "Lyra è stata sconfitta nella foresta... Game Over."
    break
  end
end 