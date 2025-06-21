# rovine_magiche.rb
require 'securerandom'

# --- Classi base ---
class Magia
  attr_accessor :nome, :danno, :tipo
  def initialize(nome, danno, tipo)
    @nome = nome
    @danno = danno
    @tipo = tipo # :attacco, :controllo, :ambiente
  end
end

class Personaggio
  attr_accessor :nome, :vita, :mana, :posizione
  def initialize(nome, vita, mana)
    @nome = nome
    @vita = vita
    @mana = mana
    @posizione = 0
  end
  def vivo?
    @vita > 0
  end
end

class Nemico < Personaggio
  attr_accessor :tipo, :stato
  def initialize(tipo, vita, mana)
    super(tipo, vita, mana)
    @tipo = tipo
    @stato = :normale
  end
end

class Boss < Personaggio
  attr_accessor :forma
  def initialize
    super('Lich delle Rovine', 120, 80)
    @forma = :lich
  end
  def cambia_forma
    if @forma == :lich
      @forma = :ombra
      puts "Il Lich si trasforma in un'Ombra Gigante!"
      @vita += 30
    else
      @forma = :lich
      puts "Il Lich riprende la sua forma originale!"
      @mana += 20
    end
  end
  def attacco_magico(giocatore)
    if @forma == :lich
      puts "Il Lich lancia una magia oscura!"
      danno = 18
      giocatore.vita -= danno
      puts "Elandor subisce #{danno} danni!"
    else
      puts "L'Ombra Gigante avvolge Elandor nella tenebra!"
      danno = 12
      giocatore.vita -= danno
      puts "Elandor subisce #{danno} danni!"
    end
  end
end

class Enigma
  attr_accessor :descrizione, :soluzione, :risolto
  def initialize(descrizione, soluzione)
    @descrizione = descrizione
    @soluzione = soluzione
    @risolto = false
  end
  def tenta(sol)
    if sol.strip.downcase == @soluzione.strip.downcase
      @risolto = true
      puts "L'enigma si dissolve!"
      true
    else
      puts "La magia non reagisce..."
      false
    end
  end
end

class Portale
  attr_accessor :aperto
  def initialize
    @aperto = false
  end
  def apri
    @aperto = true
    puts "Il portale magico si apre!"
  end
end

# --- Giocatore ---
class Giocatore < Personaggio
  attr_accessor :magie, :tempesta_ricarica
  def initialize
    super('Elandor', 85, 60)
    @magie = [
      Magia.new('Tempesta Arcana', 28, :attacco),
      Magia.new('Sollevamento', 0, :ambiente),
      Magia.new('Gelo', 0, :controllo),
      Magia.new('Sblocco Magico', 0, :ambiente)
    ]
    @tempesta_ricarica = 0
  end
  def tempesta_arcana(nemici)
    if @tempesta_ricarica == 0 && @mana >= 18
      puts "Elandor scatena TEMPESTA ARCANA!"
      nemici.each do |n|
        next unless n.vivo?
        puts "#{n.nome} viene colpito per 28 danni!"
        n.vita -= 28
      end
      @mana -= 18
      @tempesta_ricarica = 3
    else
      puts "Tempesta Arcana non è pronta o mana insufficiente!"
    end
  end
  def solleva_piattaforma
    puts "Solleva una piattaforma magica: puoi raggiungere nuove aree!"
    @mana -= 6
  end
  def gelo(nemico)
    if @mana >= 8
      puts "Congeli #{nemico.nome}!"
      nemico.stato = :congelato
      @mana -= 8
    else
      puts "Mana insufficiente!"
    end
  end
  def sblocco_magico(portale)
    if @mana >= 10
      portale.apri
      @mana -= 10
    else
      puts "Mana insufficiente!"
    end
  end
  def turno_ricarica
    @tempesta_ricarica -= 1 if @tempesta_ricarica > 0
  end
end

# --- Ambiente e interfaccia ASCII ---
class Stanza
  attr_accessor :id, :nemici, :enigma, :portale, :tipo
  def initialize(id, tipo = :normale)
    @id = id
    @nemici = []
    @enigma = nil
    @portale = nil
    @tipo = tipo # :normale, :boss, :magica
  end
  def ascii
    case @tipo
    when :boss
      "[B]"
    when :magica
      "[M]"
    else
      "[ ]"
    end
  end
end

class Mappa
  attr_accessor :stanze, :connessioni
  def initialize
    @stanze = []
    @connessioni = {}
    genera_stanze
  end
  def genera_stanze
    5.times { |i| @stanze << Stanza.new(i) }
    @stanze[2].tipo = :magica
    @stanze[4].tipo = :boss
    @stanze[1].enigma = Enigma.new("Recita la parola segreta: ...", "lux")
    @stanze[2].portale = Portale.new
    @stanze[3].enigma = Enigma.new("Completa la sequenza: fuoco, acqua, aria, ...?", "terra")
    @stanze[0].nemici << Nemico.new('Ombra', 22, 0)
    @stanze[2].nemici << Nemico.new('Cultista', 28, 10)
    @stanze[3].nemici << Nemico.new('Spettro', 24, 12)
    @stanze[4].nemici << Boss.new
    @connessioni = {
      0 => [1],
      1 => [0,2],
      2 => [1,3],
      3 => [2,4],
      4 => [3]
    }
  end
  def disegna(pos)
    puts "\nMappa delle Rovine:"
    @stanze.each_with_index do |s, i|
      print i == pos ? "*#{s.ascii}* " : " #{s.ascii}  "
    end
    puts
  end
end

# --- Gioco principale ---
giocatore = Giocatore.new
mappa = Mappa.new
pos = 0
puts "Sei Elandor, il mago. Esplora le rovine, risolvi enigmi e sconfiggi il Lich!"

loop do
  mappa.disegna(pos)
  stanza = mappa.stanze[pos]
  puts "\nSei nella stanza #{pos}."
  puts "Vita: #{giocatore.vita} | Mana: #{giocatore.mana}"
  
  nemici_presenti = stanza.nemici.select(&:vivo?)
  puts "Nemici: #{nemici_presenti.map(&:nome).join(', ')}" if nemici_presenti.any?
  puts "Enigma: #{stanza.enigma.descrizione}" if stanza.enigma && !stanza.enigma.risolto
  puts "Portale magico: #{stanza.portale&.aperto ? 'Aperto' : 'Chiuso'}" if stanza.portale

  azioni_possibili = []
  
  # Azione: Avanza
  azioni_possibili << { testo: "Avanza nelle rovine", azione: -> {
      puts "Dove vuoi andare? (#{mappa.connessioni[pos].join(', ')})"; nuova = gets.chomp.to_i
      if mappa.connessioni[pos].include?(nuova)
        # Controlla se il portale di destinazione è un ostacolo
        stanza_dest = mappa.stanze.find { |s| s.id == nuova }
        if stanza_dest.portale && !stanza_dest.portale.aperto
            puts "Un portale magico blocca la via!"
            pos
        else
            nuova
        end
      else
        puts "Non puoi andare lì."; pos
      end
  }}
  
  # Azioni di combattimento
  if nemici_presenti.any?
    if giocatore.tempesta_ricarica == 0 && giocatore.mana >= 18
      azioni_possibili << { testo: "Lancia Tempesta Arcana", azione: -> { giocatore.tempesta_arcana(nemici_presenti); pos }}
    end
    nemici_presenti.each do |n|
      azioni_possibili << { testo: "Attacca #{n.nome}", azione: -> {
        danno = 12; puts "Colpisci #{n.nome} per #{danno} danni."; n.vita -= danno; pos
      }}
      azioni_possibili << { testo: "Congela #{n.nome}", azione: -> { giocatore.gelo(n); pos }}
    end
  end

  # Azioni ambientali
  if stanza.tipo == :magica
    azioni_possibili << { testo: "Usa magia 'Sollevamento'", azione: -> { giocatore.solleva_piattaforma; pos }}
  end
  if stanza.portale && !stanza.portale.aperto
    azioni_possibili << { testo: "Usa 'Sblocco Magico' sul portale", azione: -> { giocatore.sblocco_magico(stanza.portale); pos }}
  end
  if stanza.enigma && !stanza.enigma.risolto
    azioni_possibili << { testo: "Risolvi enigma", azione: -> {
      puts "Inserisci soluzione:"; sol = gets.chomp; stanza.enigma.tenta(sol); pos
    }}
  end
  
  # Azione: Esci
  if pos == 0
    azioni_possibili << { testo: "Esci dalle rovine", azione: -> { puts "Hai lasciato le rovine."; exit }}
  end

  puts "\nAzioni disponibili:"
  azioni_possibili.each_with_index { |a, i| puts "#{i+1}. #{a[:testo]}" }
  scelta = gets.chomp.to_i - 1

  if scelta >= 0 && scelta < azioni_possibili.length
    nuova_pos = azioni_possibili[scelta][:azione].call
    pos = nuova_pos if nuova_pos.is_a?(Integer)
  else
    puts "Azione non valida."
  end

  # Turno nemici
  stanza.nemici.each do |n|
    next unless n.vivo?
    if n.stato == :congelato
      puts "#{n.nome} è congelato e non agisce."
      n.stato = :normale
      next
    end
    if n.is_a?(Boss)
      if SecureRandom.random_number < 0.3
        n.cambia_forma
      else
        n.attacco_magico(giocatore)
      end
    else
      danno = 10
      puts "#{n.nome} ti attacca per #{danno} danni!"
      giocatore.vita -= danno
    end
  end
  giocatore.turno_ricarica
  if giocatore.vita <= 0
    puts "Elandor è stato sconfitto... Game Over."
    break
  end
  if pos == 4 && stanza.nemici.all? { |n| !n.vivo? }
    puts "Hai sconfitto il Lich e liberato le rovine dalla magia nera! Vittoria!"
    break
  end
end 