STDOUT.sync = true # DO NOT REMOVE
# Grab the pellets as fast as you can!

# width: size of the grid
# height: top left corner is (x=0, y=0)
width, height = gets.split(" ").collect {|x| x.to_i}
height.times do
    row = gets.chomp # one line of the grid: space " " is floor, pound "#" is wall
end

#######################
$pac_id = 0
$x = 0
$y = 0
$px = 0
$py = 0
$done = true
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
        if mine do
          $pac_id = pac_id
          $x = x
          $y = y
        end
        ############################################################
    end
    visible_pellet_count = gets.to_i # all pellets in sight
    visible_pellet_count.times do
        # value: amount of points this pellet is worth
        x, y, value = gets.split(" ").collect {|x| x.to_i}

        ############################################################
        if value > 1 and $done do
          $done = false
          $px = x
          $py = y
          break
        end
        ############################################################
    end
    
    # Write an action using puts
    # To debug: STDERR.puts "Debug messages..."
    
    # puts "MOVE 0 15 10" # MOVE <pacId> <x> <y>
    ############################################################
    $done = $x == $px and $y == $py 
    puts "MOVE #{$pac_id} #{$px} #{$py}"
    ############################################################
end

############################################################



