STDOUT.sync = true # DO NOT REMOVE
# Grab the pellets as fast as you can!

# width: size of the grid
# height: top left corner is (x=0, y=0)
width, height = gets.split(" ").collect {|x| x.to_i}
height.times do
    row = gets.chomp # one line of the grid: space " " is floor, pound "#" is wall
end

#######################
$done = true
$pac_id = -1
$x = -1
$y = -1
$px = -1
$py = -1
$pellets = []
#######################

# game loop
loop do
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
        if mine
          $pac_id = pac_id
          $x = x
          $y = y
        end
        ############################################################
    end

    ######################
    $pellets = []
    ######################

    visible_pellet_count = gets.to_i # all pellets in sight
    visible_pellet_count.times do
        # value: amount of points this pellet is worth
        x, y, value = gets.split(" ").collect {|x| x.to_i}

        ############################################################
        if value > 0
          $pellets << { "x" => x, "y" => y, "v" => value }
        end
        ############################################################
    end
    
    # Write an action using puts
    # To debug: STDERR.puts "Debug messages..."
    
    # puts "MOVE 0 15 10" # MOVE <pacId> <x> <y>
    ############################################################
    if $x == $px and $y == $py 
      $done = true
    end

    if $done
      $px = -1
      $py = -1

      high_val = $pellets.select { |p| p["v"] > 1 }
      if high_val.empty?
        prand = $pellets.sample
        $px = prand["x"]
        $py = prand["y"]
      else
        $px = high_val[0]["x"]
        $py = high_val[0]["y"]
      end
    end
    
    puts "MOVE #{$pac_id} #{$px} #{$py}"
    ############################################################
end