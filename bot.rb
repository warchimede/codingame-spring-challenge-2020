STDOUT.sync = true # DO NOT REMOVE
# Grab the pellets as fast as you can!

# width: size of the grid
# height: top left corner is (x=0, y=0)
width, height = gets.split(" ").collect {|x| x.to_i}
map = Array.new(height, "X")
(0...height).step do |y|
    row = gets.chomp # one line of the grid: space " " is floor, pound "#" is wall
    map[y] = row.chars 
end

####################### Globals
$Map = map
$pacs = {}
$new_pacs = {}
$pellets = []
#######################

# game loop
loop do
    ############################################################
    # Reset new_pacs
    $new_pacs = {}
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
          STDERR.puts "DATA PAC: #{pac_id}"
          if $pacs[pac_id].nil?
            $new_pacs[pac_id] = {
              'x' => x,
              'y' => y,
              'last_x' => x,
              'last_y' => y,
              'dest_x' => x,
              'dest_y' => y
            }
          else
            $new_pacs[pac_id] = $pacs[pac_id]
            $new_pacs[pac_id]['last_x'] = $pacs[pac_id]['x']
            $new_pacs[pac_id]['last_y'] = $pacs[pac_id]['y']
            $new_pacs[pac_id]['x'] = x
            $new_pacs[pac_id]['y'] = y
          end
        end
        ############################################################
    end

    ######################
    $pacs = $new_pacs # update pacs with the alive ones
    $pellets = []
    ######################

    visible_pellet_count = gets.to_i # all pellets in sight
    visible_pellet_count.times do
        # value: amount of points this pellet is worth
        x, y, value = gets.split(" ").collect {|x| x.to_i}

        $pellets << { "x" => x, "y" => y, "v" => value }
    end
    
    # Write an action using puts
    # To debug: STDERR.puts "Debug messages..."
    
    # puts "MOVE 0 15 10" # MOVE <pacId> <x> <y>
    ############################################################
    high_value_pellets = $pellets.select { |p| p["v"] == 10 }

    # Destination selection for pacs which are arrived or stuck in place
    $pacs.each do |pac_id, pos|
      STDERR.puts "PAC: #{pac_id}"

      arrived = pos['x'] == pos['dest_x'] and pos['y'] == pos['dest_y']
      stuck = pos['x'] == pos['last_x'] and pos['y'] == pos['last_y']
      if arrived or stuck
        # In case no pellet in sight....
        possible_pos = [
          {'x' => pos['x'], 'y' => pos['y']-1 },
          {'x' => pos['x']+1, 'y' => pos['y'] },
          {'x' => pos['x'], 'y' => pos['y']+1 },
          {'x' => pos['x']-1, 'y' => pos['y'] }
        ].select { |p| 
          y = p['y']
          x = p['x']
          $Map[y][x] != "#"
        }
        dest = possible_pos.sample

        # In case of pellets
        unless $pellets.empty?
          dest = $pellets.sample

          # Better path: get the furthest pellet in one direction, in hope to get more on the way ?

          
          # Best path: get the closest high value pellet if there is one in sight
          unless high_value_pellets.empty?
            dest = high_value_pellets[0]
            high_value_pellets.each do |pellet|
              actual_dist = (pos['x'] - dest['x'])**2 + (pos['y'] - dest['y'])**2
              pellet_dist = (pos['x'] - pellet['x'])**2 + (pos['y'] - pellet['y'])**2

              dest = pellet if pellet_dist < actual_dist
            end
          end
        end
        
        $pacs[pac_id]['dest_x'] = dest['x']
        $pacs[pac_id]['dest_y'] = dest['y']
      end
    end
    
    # Generate action
    action = []
    $pacs.each do |pac_id, pos|
      action << "MOVE #{pac_id} #{pos['dest_x']} #{pos['dest_y']}"
    end
    puts action.join('|')
    ############################################################
end