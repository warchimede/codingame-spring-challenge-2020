STDOUT.sync = true # DO NOT REMOVE
# Grab the pellets as fast as you can!

# width: size of the grid
# height: top left corner is (x=0, y=0)
$Width, $Height = gets.split(" ").collect {|x| x.to_i}
map = Array.new($Height, "X")
(0...$Height).step do |y|
    row = gets.chomp # one line of the grid: space " " is floor, pound "#" is wall
    map[y] = row.chars 
end

####################### Globals
$Map = map
$pacs = {}
$new_pacs = {}
$pellets = []
$high_value_pellets = []
#######################

def reset
  $new_pacs = {}
  $pellets = []
  $high_value_pellets = []
end

def possible_positions(pos)
  [ # all possible directions
    {'x' => pos['x']+1, 'y' => pos['y'] },
    {'x' => pos['x'], 'y' => pos['y']+1 },
    {'x' => pos['x']-1, 'y' => pos['y'] },
    {'x' => pos['x'], 'y' => pos['y']-1 }
  ].select { |p| # stay in the map
    p['x'] > 0 and p['x'] < $Width and p['y'] > 0 and p['y'] < $Height
  }.select { |p| # filter walls
    y = p['y']
    x = p['x']
    $Map[y][x] != "#"
  }
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
    # Need to remove dead pacs, so checkin only alive pacs
    if mine
      if $pacs[pac_id].nil?
        $new_pacs[pac_id] = {
          'x' => x,
          'y' => y,
          'last_x' => x,
          'last_y' => y,
          'dest_x' => x,
          'dest_y' => y,
          'cd' => ability_cooldown,
        }
      else
        $new_pacs[pac_id] = $pacs[pac_id]
        $new_pacs[pac_id]['last_x'] = $pacs[pac_id]['x']
        $new_pacs[pac_id]['last_y'] = $pacs[pac_id]['y']
        $new_pacs[pac_id]['x'] = x
        $new_pacs[pac_id]['y'] = y
        $new_pacs[pac_id]['cd'] = ability_cooldown
      end
    end
    ############################################################
  end

  ######################
  $pacs = $new_pacs # update pacs with the alive ones
  ######################

  visible_pellet_count = gets.to_i # all pellets in sight
  visible_pellet_count.times do
    # value: amount of points this pellet is worth
    x, y, value = gets.split(" ").collect {|x| x.to_i}

    $pellets << { "x" => x, "y" => y, "v" => value }
    $high_value_pellets << { "x" => x, "y" => y, "v" => value } if value == 10
  end
    
  # Write an action using puts
  # To debug: STDERR.puts "Debug messages..."
    
  # puts "MOVE 0 15 10" # MOVE <pacId> <x> <y>
  ############################################################

  # PATH FINDING
  # Destination selection for pacs which are arrived or stuck in place
  $pacs.each do |pac_id, pos|
    arrived = pos['x'] == pos['dest_x'] and pos['y'] == pos['dest_y']
    stuck = pos['x'] == pos['last_x'] and pos['y'] == pos['last_y']

    if arrived
      # Stay if cannot move
      dest = pos

      if $pellets.empty?
        # No pellet in sight....
        possible_pos = possible_positions pos

        # filter other pacs positions
        if possible_pos.length > 1
          possible_pos = possible_pos.select do |p|
            res = true
            $pacs.each do |p_pac_id, p_pos|
              unless pac_id == p_pac_id
                res = res and (p['x'] != p_pos['x'] or p['y'] != p_pos['y'])
              end
            end
          end
        end

        # remove last position
        if possible_pos.length > 1
          possible_pos = possible_pos.select do |p|
            p['x'] != pos['last_x'] or p['y'] != pos['last_y']
          end
        end

        dest = possible_pos.sample unless possible_pos.empty?
      else
        # In case of pellets
        if $high_value_pellets.empty? # Better path: get the closest pellet in one direction
          dest = $pellets.sample
          current_dist = (pos['x'] - dest['x'])**2 + (pos['y'] - dest['y'])**2
          $pellets.each do |pellet|
            pellet_dist = (pos['x'] - pellet['x'])**2 + (pos['y'] - pellet['y'])**2
            if pellet_dist < current_dist
              dest = pellet
              current_dist = pellet_dist
            end
          end
        else # Best path: get the closest high value pellet if there is one in sight
          dest = $high_value_pellets.sample
          current_dist = (pos['x'] - dest['x'])**2 + (pos['y'] - dest['y'])**2
          $high_value_pellets.each do |pellet|
            pellet_dist = (pos['x'] - pellet['x'])**2 + (pos['y'] - pellet['y'])**2
            if pellet_dist < current_dist
              dest = pellet
              current_dist = pellet_dist
            end
          end
        end
      end
      
      $pacs[pac_id]['dest_x'] = dest['x']
      $pacs[pac_id]['dest_y'] = dest['y']

    elsif stuck
      # Stay if cannot move
      dest = pos

      possible_pos = possible_positions pos

      # filter other pacs positions
      if possible_pos.length > 1
        possible_pos = possible_pos.select do |p|
          res = true
          $pacs.each do |p_pac_id, p_pos|
            unless pac_id == p_pac_id
              res = res and (p['x'] != p_pos['x'] or p['y'] != p_pos['y'])
            end
          end
        end
      end

      # remove last position
      if possible_pos.length > 1
        possible_pos = possible_pos.select do |p|
          p['x'] != pos['last_x'] or p['y'] != pos['last_y']
        end
      end

      dest = possible_pos.sample unless possible_pos.empty?

      $pacs[pac_id]['dest_x'] = dest['x']
      $pacs[pac_id]['dest_y'] = dest['y']
    end
  end
    
  # Generate action
  action = []
  $pacs.each do |pac_id, pos|
    if $pacs[pac_id]['cd'] == 0
      action << "SPEED #{pac_id}"
    else
      action << "MOVE #{pac_id} #{pos['dest_x']} #{pos['dest_y']}"
    end
  end
  puts action.join('|')
  ############################################################
end