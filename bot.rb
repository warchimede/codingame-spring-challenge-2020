STDOUT.sync = true # DO NOT REMOVE
# Grab the pellets as fast as you can!

####################### MODEL
# Debug
def log(message)
  STDERR.puts message
end

# Type
$Rock = "ROCK"
$Paper = "PAPER"
$Scissors = "SCISSORS"

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
  attr_accessor :id, :type, :mine, :pos, :last_pos, :dest, :stl, :cd, :dead
  def initialize(id, type, mine, pos, stl, cd)
    @id = id
    @type = type
    @mine = mine
    @pos = pos
    @last_pos = Position.new(-1, -1)
    @dest = Position.new(-1, -1)
    @stl = stl
    @cd = cd
    @dead = false
  end

  def arrived?
    @pos.x == @dest.x and @pos.y == @dest.y
  end

  def stuck?
    @pos.x == @last_pos.x and @pos.y == @last_pos.y
  end

  def possible_next_positions(width, height, map)
    [ # all possible directions
      Position.new(@pos.x+1, @pos.y),
      Position.new(@pos.x, @pos.y+1),
      Position.new(@pos.x-1, @pos.y),
      Position.new(@pos.x, @pos.y-1)
    ].select { |p| # stay in the map
      p.x >= 0 and p.x < width and p.y >= 0 and p.y < height
    }.select { |p| # filter walls
      y = p.y
      x = p.x
      map[y][x] != "#"
    }
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

def distance(p1, p2)
  (p1.x - p2.x)**2 + (p1.y - p2.y)**2
end

#######################

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
$pellets = []
$super_pellets = []
#######################

def reset
  $pellets = []
  $super_pellets = []
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
        pac.last_pos.x = pac.pos.x
        pac.last_pos.y = pac.pos.y
        pac.pos.x = x
        pac.pos.y = y
        pac.stl = speed_turns_left
        pac.cd = ability_cooldown
        $pacs[pac_id] = pac
      end
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
      $pellets << pellet
    end
  end
    
  # Write an action using puts
  # To debug: STDERR.puts "Debug messages..."
    
  # puts "MOVE 0 15 10" # MOVE <pacId> <x> <y>
  ############################################################  
  # PATH FINDING
  # High value pellets choose pacs
  unless $super_pellets.empty?
    high_val = $super_pellets.select do |hp| # choose only not targeted ones
      res = true
      $pacs.each do |id, pac|
        res = res and (hp.pos.x != pac.dest.x or hp.pos.y != pac.dest.y)
      end
    end

    high_val.each do |hp| # choose the closest available pac
      pacs = $pacs.select do |id, pac|
        pac.arrived?
      end

      unless pacs.empty?
        pac_id = pacs.keys[0]
        current_dist = distance pacs[pac_id].pos, hp.pos
        pacs.keys.each do |p_id|
          hp_dist = distance pacs[p_id].pos, hp.pos
          if hp_dist < current_dist
            pac_id = p_id
            current_dist = hp_dist
          end
        end
        pac = $pacs[pac_id]
        pac.dest = hp.pos
        $pacs[pac_id] = pac
      end
    end
  end

  arrived = $pacs.select do |p_id, pac|
    pac.arrived?
  end

  stuck = $pacs.select do |p_id, pac|
    pac.stuck?
  end

  arrived.each do |pac_id, pac|
    # Stay if cannot move
    dest = pac.pos

    if $pellets.empty?
      # No pellet in sight....
      possible_pos = pac.possible_next_positions $Width, $Height, $Map

      # filter other pacs positions
      if possible_pos.length > 1
        possible_pos = possible_pos.select do |p|
          res = true
          $pacs.each do |p_pac_id, p_pac|
            unless pac_id == p_pac_id
              res = res and (p.x != p_pac.pos.x or p.y != p_pac.pos.y)
            end
          end
        end
      end

      # remove last position
      if possible_pos.length > 1
        possible_pos = possible_pos.select do |p|
          p.x != p_pac.last_pos.x or p.y != p_pac.last_pos.y
        end
      end

      dest = possible_pos.sample unless possible_pos.empty?
    else
      # In case of pellets
      dest = $pellets.sample.pos

      # Better path: get the closest pellet in one direction  
      current_dist = distance pac.pos, dest
      $pellets.each do |pellet|
        pellet_dist = distance pac.pos, pellet.pos
        if pellet_dist < current_dist
          dest = pellet.pos
          current_dist = pellet_dist
        end
      end
    end
    
    pac.dest = dest
    $pacs[pac_id] = pac
  end

  stuck.each do |pac_id, pac|
    # Stay if cannot move
    dest = pac.pos

    possible_pos = pac.possible_next_positions $Width, $Height, $Map

    # filter other pacs positions
    if possible_pos.length > 1
      possible_pos = possible_pos.select do |p|
        res = true
        $pacs.each do |p_pac_id, p_pac|
          unless pac_id == p_pac_id
            res = res and (p.x != p_pac.pos.x or p.y != p_pac.pos.y)
          end
        end
      end
    end

    # remove last position
    if possible_pos.length > 1
      possible_pos = possible_pos.select do |p|
        p.x != pac.last_pos.x or p.y != pac.last_pos.x
      end
    end

    dest = possible_pos.sample unless possible_pos.empty?

    pac.dest = dest
    $pacs[pac_id] = pac
  end
    
  # Generate action
  action = []
  $pacs.each do |pac_id, pac|
    if $pacs[pac_id].cd == 0
      action << "SPEED #{pac_id}"
    else
      action << "MOVE #{pac_id} #{pac.dest.x} #{pac.dest.y}"
    end
  end
  puts action.join('|')
  ############################################################
end