# castle_quest.rb

# Classe base per personaggi
class Personaggio
  attr_accessor :nome, :vita, :attacco, :difesa

  def initialize(nome, vita, attacco, difesa)
    @nome = nome
    @vita = vita
    @attacco = attacco
    @difesa = difesa
  end

  def vivo?
    @vita > 0
  end
end

# Giocatore
class Giocatore < Personaggio
  attr_accessor :colpo_devastante_ricarica

  def initialize
    super('Ardyn', 100, 15, 5)
    @colpo_devastante_ricarica = 0
  end

  def colpo_devastante(bersaglio)
    if @colpo_devastante_ricarica == 0
      danno = (@attacco * 2.5).to_i
      puts "*WHOOOSH!* Ardyn concentra la sua energia in un COLPO DEVASTANTE! #{bersaglio.nome} subisce un danno critico di #{danno}!"
      bersaglio.vita -= danno
      @colpo_devastante_ricarica = 3
    else
      puts "Colpo Devastante non è pronto!"
    end
  end

  def turno_ricarica
    @colpo_devastante_ricarica -= 1 if @colpo_devastante_ricarica > 0
  end
end

# Nemico
class Nemico < Personaggio
  attr_accessor :tipo

  def initialize(tipo, vita, attacco, difesa)
    super(tipo, vita, attacco, difesa)
    @tipo = tipo
  end
end

# Boss
class Boss < Personaggio
  def initialize
    super('Drago Cremisi', 120, 20, 8)
  end
end

# Trappola
class Trappola
  attr_accessor :nome, :danno, :attiva, :ciclo

  def initialize(nome, danno, ciclo)
    @nome = nome
    @danno = danno
    @ciclo = ciclo # ogni quanti turni si attiva
    @attiva = false
    @turni = 0
  end

  def aggiorna
    @turni = (@turni + 1) % @ciclo
    @attiva = @turni == 0
  end

  def scatta(giocatore)
    if @attiva
      puts "*CLICK!* La trappola '#{@nome}' scatta! Subisci #{@danno} danni mentre schivi all'ultimo secondo."
      giocatore.vita -= @danno
    end
  end
end

# Stanza
class Stanza
  attr_accessor :nome, :nemici, :trappole, :muri_distruttibili, :leva, :porta_aperta

  def initialize(nome, nemici, trappole, muri_distruttibili, leva = false)
    @nome = nome
    @nemici = nemici
    @trappole = trappole
    @muri_distruttibili = muri_distruttibili
    @leva = leva
    @porta_aperta = !leva
  end

  def descrizione
    puts "\nSei in: #{@nome}"
    puts "Nemici: " + (@nemici.any? ? @nemici.map(&:nome).join(', ') : 'Nessuno')
    puts "Trappole: " + (@trappole.any? ? @trappole.map(&:nome).join(', ') : 'Nessuna')
    puts "Muri distruttibili: #{@muri_distruttibili > 0 ? @muri_distruttibili : 'Nessuno'}"
    puts "Leva presente: #{@leva ? 'Sì' : 'No'}"
    puts "Porta: #{@porta_aperta ? 'Aperta' : 'Chiusa'}"
  end

  def aggiorna_trappole(giocatore)
    @trappole.each do |t|
      t.aggiorna
      t.scatta(giocatore)
    end
  end

  def interagisci_oggetto(giocatore)
    if @leva && !@porta_aperta
      puts "Tiri una vecchia leva arrugginita. *Crrrrk!* Un meccanismo scatta e la porta di pietra si apre lentamente."
      @porta_aperta = true
    elsif @muri_distruttibili > 0
      puts "Colpisci il muro con forza. Le pietre si sgretolano rivelando un passaggio!"
      @muri_distruttibili -= 1
    else
      puts "Non c'è nulla con cui interagire."
    end
  end
end

# Funzione di combattimento a turni
def combattimento(giocatore, nemici)
  while nemici.any?(&:vivo?) && giocatore.vivo?
    puts "\nVita Ardyn: #{giocatore.vita}"
    nemici.select(&:vivo?).each do |n|
      puts "- #{n.nome} - Vita: #{n.vita}"
    end

    azioni_possibili = []

    # Azioni di attacco normale
    nemici.select(&:vivo?).each do |n|
      azioni_possibili << {
        testo: "Attacca #{n.nome}",
        azione: lambda {
          danno = [giocatore.attacco - n.difesa, 1].max
          puts "*CLANG!* La tua spada colpisce #{n.nome}, infliggendo #{danno} danni."
          n.vita -= danno
        }
      }
    end

    # Azioni per Colpo Devastante
    if giocatore.colpo_devastante_ricarica == 0
      nemici.select(&:vivo?).each do |n|
        azioni_possibili << {
          testo: "Usa COLPO DEVASTANTE su #{n.nome}",
          azione: lambda {
            giocatore.colpo_devastante(n)
          }
        }
      end
    end

    puts "\nScegli un'azione:"
    azioni_possibili.each_with_index do |opzione, i|
      puts "#{i + 1}. #{opzione[:testo]}"
    end

    scelta = gets.chomp.to_i - 1

    if scelta >= 0 && scelta < azioni_possibili.length
      azioni_possibili[scelta][:azione].call
    else
      puts "Scelta non valida. Riprova."
      next # Salta il resto del turno e fa scegliere di nuovo
    end

    giocatore.turno_ricarica

    # Turno nemici
    nemici.each do |n|
      next unless n.vivo?
      danno = [n.attacco - giocatore.difesa, 1].max
      puts "L'attacco rapido di #{n.nome} ti colpisce! Subisci #{danno} danni."
      giocatore.vita -= danno
    end
  end
  if giocatore.vivo?
    puts "Hai sconfitto i nemici in questa stanza!"
  else
    puts "Sei stato sconfitto... Game Over."
    exit
  end
end

# --- Definizione delle stanze ---
stanze = [
  Stanza.new(
    'Atrio in Rovina',
    [Nemico.new('Goblin Esploratore', 20, 7, 2)],
    [Trappola.new('Dardi a Tempo', 5, 2)],
    1
  ),
  Stanza.new(
    'Sala delle Trappole',
    [Nemico.new('Goblin Bombarolo', 25, 8, 2), Nemico.new('Goblin Ladro', 18, 6, 3)],
    [Trappola.new('Fiamme Periodiche', 10, 3)],
    2,
    true
  ),
  Stanza.new(
    'Corridoio Infuocato',
    [Nemico.new('Goblin Guerriero', 30, 10, 4)],
    [Trappola.new('Pozza di Fuoco', 12, 2)],
    0
  ),
  Stanza.new(
    'Sala del Drago',
    [Boss.new],
    [Trappola.new('Soffio di Fuoco', 15, 2)],
    0
  )
]

# --- Gioco principale ---
giocatore = Giocatore.new
puts "Benvenuto, Ardyn! Devi salvare la principessa Elira dal Drago Cremisi."

stanze.each_with_index do |stanza, idx|
  stanza.descrizione
  # Loop principale della stanza, fuori dal combattimento
  loop do
    if stanza.nemici.any?(&:vivo?)
      combattimento(giocatore, stanza.nemici)
    end
    break unless giocatore.vivo?

    # Costruisci menu azioni dinamico
    azioni_stanza = []
    if (stanza.leva && !stanza.porta_aperta) || stanza.muri_distruttibili > 0
      azioni_stanza << { testo: "Interagisci con l'ambiente", azione: -> { stanza.interagisci_oggetto(giocatore); false } }
    end
    if stanza.porta_aperta && stanza.muri_distruttibili == 0 && stanza.nemici.none?(&:vivo?)
      azioni_stanza << { testo: "Prosegui alla stanza successiva", azione: -> { puts "Prosegui..."; true } }
    end

    if azioni_stanza.empty?
      puts "Non c'è più nulla da fare qui. Prosegui." if stanza.nemici.none?(&:vivo?)
      break
    end

    puts "\nCosa vuoi fare?"
    azioni_stanza.each_with_index { |a, i| puts "#{i+1}. #{a[:testo]}" }
    scelta = gets.chomp.to_i - 1

    if scelta >= 0 && scelta < azioni_stanza.length
      # l'azione ritorna true se bisogna uscire dal loop (proseguire)
      break if azioni_stanza[scelta][:azione].call
    else
      puts "Scelta non valida."
    end
  end
end

if giocatore.vivo?
  puts "\nCon un ultimo colpo, il Drago Cremisi crolla a terra, sconfitto. Dalle ceneri emerge la principessa Elira, salva. Hai trionfato!"
end