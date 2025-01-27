STDOUT.sync = true # DO NOT REMOVE
# Grab the pellets as fast as you can!

# Debug
def log(message)
  STDERR.puts message
end

# Type
$Rock = "ROCK"
$Paper = "PAPER"
$Scissors = "SCISSORS"
$Dead = "DEAD"

# Map
$Wall = "#"
$Space = " "
$Xplored = "x"
# width: size of the grid
# height: top left corner is (x=0, y=0)
$Width, $Height = gets.split(" ").collect {|x| x.to_i}
map = Array.new($Height, "#")
(0...$Height).step do |y|
    row = gets.chomp # one line of the grid: space " " is floor, pound "#" is wall
    map[y] = row.chars 
end

####################### Globals
$Map = map
$pacs = {}
$enemies = {}
$super_pellets = []
$actions = {}
####################### Models
# Position
class Position
  attr_accessor :x, :y
  def initialize(x, y)
    @x = x
    @y = y
  end
end

# Pac
class Pac
  attr_accessor :id, :type, :mine, :pos, :last_pos, :dest, :stl, :cd, :pellets
  def initialize(id, type, mine, pos, stl, cd)
    @id = id
    @type = type
    @mine = mine
    @pos = pos
    @last_pos = pos
    @dest = pos
    @stl = stl
    @cd = cd
    @pellets = []
  end

  def arrived?
    (@pos.x == @dest.x and @pos.y == @dest.y) or $Map[@dest.y][@dest.x] == $Xplored
  end

  def stuck?
    @pos.x == @last_pos.x and @pos.y == @last_pos.y and @stl != 5
  end

  def next_type(enemy)
    case enemy.type
    when $Rock
      return $Paper
    when $Paper
      return $Scissors
    when $Scissors
      return $Rock
    when $Dead
      return @type
    end
  end

  def move
    "MOVE #{@id} #{@dest.x} #{@dest.y}"
  end

  def speed
    "SPEED #{@id}"
  end

  def switch(type)
    "SWITCH #{@id} #{type}"
  end

  def type_action_or_nil
    if @cd != 0 or $enemies.empty?
      return nil
    end

    closest_enemy = $enemies.values[0]
      current_dist = distance @pos, closest_enemy.pos
      $enemies.values.each do |enemy|
        dist = distance @pos, enemy.pos
        if dist < current_dist
          current_dist = dist
          closest_enemy = enemy
        end
      end
      if current_dist < 3 and closest_enemy.cd != 0
        type = next_type closest_enemy
        unless type == @type
          return switch type
        end
      end
      return nil
  end

  def next_action
    log @id

    unless @pellets.empty?
      chosen_pellet = @pellets[0]
      dest = chosen_pellet.pos
      current_dist = distance @pos, chosen_pellet.pos
      @pellets.each do |pellet|
        p_dist = distance @pos, pellet.pos
        if p_dist < current_dist
          current_dist = p_dist
          dest = pellet.pos
          chosen_pellet = pellet
        end
      end
      @dest = dest
      
      log "#{@dest.x} #{@dest.y}"

      if @stl > 0 and (distance @pos, @dest) == 1
        possible_pos = possible_next_positions @dest

        log "1 #{possible_pos}"

        if possible_pos.length > 1
          possible_pos = possible_pos.select do |pos|
            pos.x != @pos.x and pos.y != @pos.y
          end
        end

        log "2 #{possible_pos}"

        if possible_pos.length > 1
          possible_pos = possible_pos.select do |pos|
            $Map[pos.y][pos.x] != $Xplored
          end
        end

        log "3 #{possible_pos}"

        @dest = possible_pos.sample unless possible_pos.empty?
      end

      if stuck? # do not be stubborn when stuck
        dest = @pos
        possible_pos = possible_next_positions @pos
        dest = possible_pos.sample unless possible_pos.empty?
        @dest = dest
        log "pellet stuck"
      end
      log "pellet #{@dest.x} #{@dest.y}"
      return move
    end

    if stuck?
      dest = @pos
      possible_pos = possible_next_positions @pos
      dest = possible_pos.sample unless possible_pos.empty?
      @dest = dest

      log "stuck #{@dest.x} #{@dest.y}"
      return move
    end
    
    # Go see further
    if arrived?
      @dest = closest_unXplored_pos @pos
      log "go further #{@dest.x} #{@dest.y}"
    end

    return speed if @cd == 0

    log "advance #{@dest.x} #{@dest.y}"
    return move
  end
end

# Pellet
class Pellet
  attr_accessor :pos, :value
  def initialize(pos, value)
    @pos = pos
    @value = value
  end
end

# Tinder match
class Match
  attr_accessor :pac, :pellet, :dist
  def initialize(pac, pellet)
    @pac = pac
    @pellet = pellet
    @dist = distance pac.pos, pellet.pos
  end
end

def find_love(pacs)
  if $super_pellets.empty?
    return
  end

  matches = []
  $super_pellets.each do |pellet|
    pacs.each do |pac|
      matches << Match.new(pac, pellet)
    end
  end

  best_matches = []
  while (best_matches.length != $super_pellets.length) and (not matches.empty?) do
    match = matches[0]
    matches.each do |m|
      if m.dist < match.dist
        match = m
      end
    end
    best_matches << match
    matches = matches.select do |m|
      m.pac.id != match.pac.id
    end
  end

  best_matches.each do |bm|
    man = $pacs[bm.pac.id] # dunno wether reference or copy so...
    man.dest = bm.pellet.pos
    $pacs[bm.pac.id] = man
    $actions[bm.pac.id] = man.move
  end
end

def possible_next_positions(pos)
  [ # all possible directions
    Position.new(pos.x+1, pos.y),
    Position.new(pos.x, pos.y+1),
    Position.new(pos.x-1, pos.y),
    Position.new(pos.x, pos.y-1)
  ].select { |p| # stay in the map
    p.x >= 0 and p.x < $Width and p.y >= 0 and p.y < $Height
  }.select { |p| # filter walls
    $Map[p.y][p.x] != $Wall
  }
end

def distance(p1, p2)
  (p1.x - p2.x).abs + (p1.y - p2.y).abs
end

def walls_between_y(p1, p2)
  if p1.y != p2.y
    return true
  end

  y = p1.y
  x1 = [p1.x, p2.x].min
  x2 = [p1.x, p2.x].max

  for x in x1..x2 do
    if $Map[y][x] == $Wall
      return true
    end
  end

  return false
end

def walls_between_x(p1, p2)
  if p1.x != p2.x
    return true
  end

  x = p1.x
  y1 = [p1.y, p2.y].min
  y2 = [p1.y, p2.y].max

  for y in y1..y2 do
    if $Map[y][x] == $Wall
      return true
    end
  end

  return false
end

def random_unXplored_pos
  y = rand $Height
  x = rand $Width
  while $Map[y][x] == $Wall or $Map[y][x] == $Xplored do
    y = rand $Height
    x = rand $Width
  end

  return Position.new(x, y)
end

def closest_unXplored_pos(pos)
  result = random_unXplored_pos
  current_dist = distance result, pos
  $Map.each_with_index do |line, y|
    line.each_with_index do |column, x|
      next if column == $Wall or column == $Xplored
      position = Position.new(x, y)
      dist = distance position, pos
      if dist < current_dist
        current_dist = dist
        result = position
      end
    end
  end
  return result
end

def available(pacs)
  # filter pacs left without action
  return pacs.select do |pac|
    not $actions.keys.include? pac.id
  end
end

def reset
  $actions = {}
  $super_pellets = []
  $enemies = {}
  $pacs.each do |id, pac|
    pac.pellets = []
  end
end

# game loop
loop do
  ############################################################
  # Reset for new loop
  reset
  ############################################################
  my_score, opponent_score = gets.split(" ").collect {|x| x.to_i}
  visible_pac_count = gets.to_i # all your pacs and enemy pacs in sight
  visible_pac_count.times do
    # pac_id: pac number (unique within a team)
    # mine: true if this pac is yours
    # x: position in the grid
    # y: position in the grid
    # type_id: unused in wood leagues
    # speed_turns_left: unused in wood leagues
    # ability_cooldown: unused in wood leagues
    pac_id, mine, x, y, type_id, speed_turns_left, ability_cooldown = gets.split(" ")
    pac_id = pac_id.to_i
    mine = mine.to_i == 1
    x = x.to_i
    y = y.to_i
    speed_turns_left = speed_turns_left.to_i
    ability_cooldown = ability_cooldown.to_i

    ############################################################
    # Mark the positision explored
    $Map[y][x] = $Xplored

    if mine
      if $pacs[pac_id].nil?
        pos = Position.new(x, y)
        pac = Pac.new(pac_id, type_id, mine, pos, speed_turns_left, ability_cooldown)
        $pacs[pac_id] = pac
      else
        pac = $pacs[pac_id]
        pac.last_pos = Position.new(pac.pos.x, pac.pos.y)
        pac.pos = Position.new(x, y)
        pac.stl = speed_turns_left
        pac.cd = ability_cooldown
        pac.type = type_id
        $pacs[pac_id] = pac
      end
    else
      pos = Position.new(x, y)
      enemy = Pac.new(pac_id, type_id, mine, pos, speed_turns_left, ability_cooldown)
      $enemies[pac_id] = enemy
    end
    ############################################################
  end

  visible_pellet_count = gets.to_i # all pellets in sight
  visible_pellet_count.times do
    # value: amount of points this pellet is worth
    x, y, value = gets.split(" ").collect {|x| x.to_i}

    pellet = Pellet.new(Position.new(x, y), value)
    if pellet.value == 10
      $super_pellets << pellet
    else
      $pacs.values.each do |pac|
        if pac.pos.x == x and not walls_between_x(pac.pos, pellet.pos)
          pac.pellets << pellet
        elsif pac.pos.y == y and not walls_between_y(pac.pos, pellet.pos)
          pac.pellets << pellet
        end
      end
    end
  end
    
  ############################################################  
  alive_pacs = $pacs.values.select do |pac|
    pac.type != $Dead
  end

  # type actions
  alive_pacs.each do |pac|
    act = pac.type_action_or_nil
    $actions[pac.id] = act unless act.nil?
  end

  # filter pacs left without action
  available_pacs = available alive_pacs

  find_love available_pacs

  # again
  available_pacs = available alive_pacs

  available_pacs.each do |pac|
    $actions[pac.id] = pac.next_action
  end
  puts $actions.values.join('|')
  ############################################################
end