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

# Map
$Wall = "#"
$Space = " "
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
  attr_accessor :id, :type, :mine, :pos, :last_pos, :dest, :stl, :cd, :dead, :pellets
  def initialize(id, type, mine, pos, stl, cd)
    @id = id
    @type = type
    @mine = mine
    @pos = pos
    @last_pos = pos
    @dest = pos
    @stl = stl
    @cd = cd
    @dead = false
    @pellets = []
  end

  def arrived?
    @pos.x == @dest.x and @pos.y == @dest.y
  end

  def stuck?
    @pos.x == @last_pos.x and @pos.y == @last_pos.y
  end

  def next_type(enemy)
    case enemy.type
    when $Rock
      return $Paper
    when $Paper
      return $Scissors
    when $Scissors
      return $Rock
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

  def next_action
    log "#{@id}: #{@pellets.length}"

    if @cd == 0 and (not $enemies.empty?)
      closest_enemy = $enemies.values[0]
      current_dist = distance @pos, closest_enemy.pos
      $enemies.values.each do |enemy|
        dist = distance @pos, enemy.pos
        if dist < current_dist
          current_dist = dist
          closest_enemy = enemy
        end
      end
      if current_dist < 7
        type = next_type closest_enemy
        unless type == @type
          return switch type
        end
      end
    end

    if arrived?
      # clean pellets
      @pellets = @pellets.select do |pellet|
        pellet.pos.x != @pos.x or pellet.pos.y != @pos.y
      end

      unless $super_pellets.empty?
        chosen_pellet = $super_pellets.sample
        dest = chosen_pellet.pos
        current_dist = distance @pos, chosen_pellet.pos
        $super_pellets.each do |pellet|
          p_dist = distance @pos, pellet.pos
          if p_dist < current_dist
            current_dist = p_dist
            dest = pellet.pos
            chosen_pellet = pellet
          end
        end
        @dest = dest
        $super_pellets.delete(chosen_pellet)
        return move
      end

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
        return move
      end

      # Go see further
      possible_pos = possible_next_positions @pos, $Width, $Height, $Map
      ($Width/2).times do
        pos = possible_pos.sample
        possible_pos = possible_next_positions pos, $Width, $Height, $Map
      end

      @dest = possible_pos.sample
      return move
    end

    if stuck?
      dest = @pos
      possible_pos = possible_next_positions @pos, $Width, $Height, $Map
      dest = possible_pos.sample unless possible_pos.empty?
      @dest = dest
      return move
    end
    
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

def possible_next_positions(pos, width, height, map)
  [ # all possible directions
    Position.new(pos.x+1, pos.y),
    Position.new(pos.x, pos.y+1),
    Position.new(pos.x-1, pos.y),
    Position.new(pos.x, pos.y-1)
  ].select { |p| # stay in the map
    p.x >= 0 and p.x < width and p.y >= 0 and p.y < height
  }.select { |p| # filter walls
    y = p.y
    x = p.x
    map[y][x] != $Wall
  }
end

def distance(p1, p2)
  (p1.x - p2.x).abs + (p1.y - p2.y).abs
end

def reset
  $super_pellets = []
  $enemies = {}
  # consider all pacs are dead
  dead_pacs = {}
  $pacs.each do |id, pac|
    pac.dead = true
    dead_pacs[id] = pac
  end
  $pacs = dead_pacs
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
    if mine # TODO: also keep track of other pacs
      if $pacs[pac_id].nil?
        pos = Position.new(x, y)
        pac = Pac.new(pac_id, type_id, mine, pos, speed_turns_left, ability_cooldown)
        $pacs[pac_id] = pac
      else
        pac = $pacs[pac_id]
        pac.dead = false
        pac.last_pos = Position.new(pac.pos.x, pac.pos.y)
        pac.pos = Position.new(x, y)
        pac.stl = speed_turns_left
        pac.cd = ability_cooldown
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
        if pac.pos.x == x or pac.pos.y == y
          pac.pellets << pellet
        end
      end
    end
  end
    
  # Write an action using puts
  # To debug: STDERR.puts "Debug messages..."
    
  # puts "MOVE 0 15 10" # MOVE <pacId> <x> <y>
  ############################################################  
  action = []
  $pacs.values.shuffle.each do |pac|
    action << pac.next_action
  end
  puts action.join('|')
  ############################################################
end