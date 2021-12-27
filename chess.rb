require 'yaml'
class Chess
  attr_accessor :current_position, :board, :turn_number, :last_move, :black_king_pos,
                :colour, :pos_from, :pos_to, :piece, :avail_moves, :enpassant,
                :white_king_pos, :wrook_left_route, :wrook_right_route, :checkmate,
                :brook_right_route, :brook_left_route, :all_squares_reaches, :mate_counter

  def initialize
    @board = [['0', '1 ', '2 ', '3 ', '4 ', '5 ', '6 ', '7 ', '8 '],
              ['1', 'RB', 'NB', 'BB', 'QB', 'KB', 'BB', 'NB', 'RB'],
              ['2', 'PB', 'PB', 'PB', 'PB', 'PB', 'PB', 'PB', 'PB'],
              ['3', '  ', '  ', '  ', '  ', '  ', '  ', '  ', '  '],
              ['4', '  ', '  ', '  ', '  ', '  ', '  ', '  ', '  '],
              ['5', '  ', '  ', '  ', '  ', '  ', '  ', '  ', '  '],
              ['6', '  ', '  ', '  ', '  ', '  ', '  ', '  ', '  '],
              ['7', 'PW', 'PW', 'PW', 'PW', 'PW', 'PW', 'PW', 'PW'],
              ['8', 'RW', 'NW', 'BW', 'QW', 'KW', 'BW', 'NW', 'RW']]
    #@board = [['0', '1 ', '2 ', '3 ', '4 ', '5 ', '6 ', '7 ', '8 '],
    #          ['1', 'RB', '  ', '  ', '  ', 'KB', 'BB', '  ', 'RB'],
    #          ['2', 'PB', 'PB', '  ', '  ', 'QB', 'PB', 'PB', 'PB'],   # test board
    #          ['3', '  ', '  ', '  ', '  ', '  ', 'NB', '  ', '  '],
    #          ['4', '  ', 'PW', '  ', '  ', 'PB', '  ', 'BW', '  '],
    #          ['5', 'BW', '  ', '  ', '  ', 'PW', '  ', '  ', '  '],
    #          ['6', '  ', 'QW', '  ', '  ', '  ', '  ', '  ', '  '],
    #          ['7', '  ', '  ', '  ', '  ', '  ', '  ', '  ', '  '],
    #          ['8', '  ', '  ', '  ', '  ', 'KW', '  ', '  ', 'RW']]
    @turn_number = 1 #change # @piece = @piece[0] + @colour, such as PB
    @avail_moves, @pos_from, @pos_to, @colour, @piece = nil
    @last_move = [nil, nil, nil]
    @checked = false
    @enpassant = false
    @white_king_pos = [[8, 5], false] # [1] is true if king moves
    @black_king_pos = [[1, 5], false]
    @wrook_left_route = [false, false] # [0] checks if the rooks are in the OG position
    @wrook_right_route = [false, false] # [1] checks if the castle routes are checked
    @brook_left_route = [false, false]
    @brook_right_route = [false, false]
    @all_squares_reaches = [] # Needed so a method only needs doing once.
    @mate_counter = 0
  end
  # maybe p instructions on how to type positions
  def pick_pos_from
    position = [nil, nil]
    puts 'Type D to draw, S to save the game.'
    loop do
      print 'Choose your piece, first rank second file: '
      rank = gets.chomp
      if rank[0].to_i.between?(1, 8) && rank[1].to_i.between?(1, 8)
        position[0] = rank[0].to_i
        position[1] = rank[1].to_i
        break
      elsif rank.upcase == 'D' || rank.upcase == 'S'
        position.pop
        position[0] = rank.upcase
        break
      else
        puts 'You can only type 1-8, D and S. '
        redo
      end
    end
    position
  end
  def pick_pos_to
    position = [nil, nil]
    puts 'Or type T to redo the move.'
    loop do
      print 'Choose your rank and file: '
      rank = gets.chomp
      if rank[0].to_i.between?(1, 8) && rank[1].to_i.between?(1, 8)
        position[0] = rank[0].to_i
        position[1] = rank[1].to_i
        break
      elsif rank.upcase == 'T'
        position.pop
        position[0] = rank.upcase
        break
      else
        puts 'You can only type 1-8 and T. '
        redo
      end
    end
    position
  end
  def colour_decide
    @colour = 'W' if (@turn_number % 2).odd?
    @colour = 'B' if (@turn_number % 2).even?
  end
  def checkmate?
    if (@checked && @colour == 'B' && available_moves_king(@black_king_pos[0]) == [] &&
       (checkmate_loop || @mate_counter == 2)) ||
       (@checked && @colour == 'W' && available_moves_king(@white_king_pos[0]) == [] &&
       (checkmate_loop || @mate_counter == 2))
      puts "Checkmate, #{colour_name(@colour)} has won!"
      File.delete('savegame.yml') if File.exist?('savegame.yml')
      exit
    elsif @checked
      puts 'CHECK'
    end
  end
  def move_from_to
    loop do
      colour_decide
      checkmate?
      puts "#{colour_name(@colour).capitalize} to move: "
      temp = pick_pos_from
      if temp[0] == 'D'
        puts 'A draw is agreed.'
        File.delete('savegame.yml') if File.exist?('savegame.yml')
        exit
      elsif temp[0] == 'S'
        save_game
        puts 'Saved!'
        exit
      else
        @pos_from = temp
      end
      if @pos_from.include?('RE')
        puts 'Redo the move.'
        redo
      end
      if @board[@pos_from[0]][@pos_from[1]] == '  ' # Ensure not blank square
        puts 'Wrong square'
        redo
      elsif @board[@pos_from[0]][@pos_from[1]][1] != @colour # Ensure right colour
        puts 'Wrong colour'
        redo
      end
      @piece = @board[@pos_from[0]][@pos_from[1]]
      # p moves_under_check
      # p all_squares_reachedv2
      case @piece[0]
      when 'R'
        @avail_moves = available_moves_rook(@pos_from)
      when 'N'
        @avail_moves = available_moves_knight(@pos_from)
      when 'B'
        @avail_moves = available_moves_bishop(@pos_from)
      when 'Q'
        @avail_moves = available_moves_queen(@pos_from)
      when 'K'
        @avail_moves = available_moves_king(@pos_from)
      when 'P'
        @avail_moves = available_moves_pawn(@pos_from)
      end
      if @avail_moves == []
        if @checked
          puts 'Your king is under check, change a move'
        else
          puts "This #{full_name(@piece[0])} has nowhere to go, change a piece"
        end
        @enpassant = false
        redo
      end
      puts "Choose your destination: #{@avail_moves}"
      @pos_to = pick_pos_to
      if @pos_to[0] == 'T'
        puts 'Redo the move.'
        @enpassant = false
        redo
      end
      unless @avail_moves.include?(@pos_to)
        puts 'Your piece can not get there'
        @enpassant = false
        redo
      end
      en_passant_check
      @last_move[0] = @piece
      @last_move[1] = @pos_from
      @last_move[2] = @pos_to
      @board[@pos_to[0]][@pos_to[1]] = @piece
      @board[@pos_from[0]][@pos_from[1]] = '  '
      judgements
      @turn_number += 1
      break
    end
  end
  def judgements
    promotion?
    new_king_pos         # castle series
    rook_pos_check       # castle series
    castling             # castle series
    all_squares_reached  # all squared reached by opponent pieces
    castle_right         # castle series
    checked?
  end
  def file_existence
    return unless File.exist?('savegame.yml')
    loop do
      print 'Do you want to resume your game? (Y/N) '
      answer = gets.chomp.downcase
      case answer
      when 'y'
        load_game
        break
      when 'n'
        File.delete('savegame.yml')
        puts 'A new game starts. '
        break
      else
        redo
      end
    end
  end
  def game
    file_existence
    loop do
      p @board
      move_from_to
    end
  end
  def save_game
    File.delete('savegame.yml') if File.exist?('savegame.yml')
    saved = { board: @board, turn_number: @turn_number, last_move: @last_move, black_king_pos: @black_king_pos,
              white_king_pos: @white_king_pos, wrook_left_route: @wrook_left_route, wrook_right_route: @wrook_right_route,
              brook_left_route: @brook_left_route, brook_right_route: @brook_right_route }
    file = File.open('savegame.yml', 'w')
    file.puts(YAML.dump(saved))
    file.close
  end
  def load_game
    loaded = File.open('savegame.yml')
    saved = YAML.load(loaded)
    @board = saved[:board]
    @turn_number = saved[:turn_number]
    @last_move = saved[:last_move]
    @black_king_pos = saved[:black_king_pos]
    @white_king_pos = saved[:white_king_pos]
    @wrook_left_route = saved[:wrook_left_route]
    @wrook_right_route = saved[:wrook_right_route]
    @brook_left_route = saved[:brook_left_route]
    @brook_right_route = saved[:brook_right_route]
    loaded.close
  end
  def available_moves_rook(pos_from)
    avail_moves = []
    piece_container = @board[pos_from[0]][pos_from[1]]
    @board[pos_from[0]][pos_from[1]] = '  '
    limited_region = moves_under_check
    @board[pos_from[0]][pos_from[1]] = piece_container
    (pos_from[1] - 1).downto(1) do |i| # West branch, (5,4) - 5,3 - 5,2 - 5,1
      if @board[pos_from[0]][i] != '  '
        avail_moves.push([pos_from[0], i]) unless @board[pos_from[0]][i][1] == @board[pos_from[0]][pos_from[1]][1]
        break
      else
        avail_moves.push([pos_from[0], i])
      end
    end
    (pos_from[0] - 1).downto(1) do |i|   # North branch, (5,4) - 4,4 - 3,4 - 2,4 - 1,4
      if @board[i][pos_from[1]] != '  '
        avail_moves.push([i, pos_from[1]]) unless @board[i][pos_from[1]][1] == @board[pos_from[0]][pos_from[1]][1]
        break
      else
        avail_moves.push([i, pos_from[1]])
      end
    end
    ((pos_from[1] + 1)..8).each do |i|   # East branch, (5,4) - 5,5 - 5,6 - 5,7 - 5,8
      if @board[pos_from[0]][i] != '  '
        avail_moves.push([pos_from[0], i]) unless @board[pos_from[0]][i][1] == @board[pos_from[0]][pos_from[1]][1]
        break
      else
        avail_moves.push([pos_from[0], i])
      end
    end
    ((pos_from[0] + 1)..8).each do |i|   # South branch, (5,4) - 6,4 - 7,4 - 8,4
      if @board[i][pos_from[1]] != '  '
        avail_moves.push([i, pos_from[1]]) unless @board[i][pos_from[1]][1] == @board[pos_from[0]][pos_from[1]][1]
        break
      else
        avail_moves.push([i, pos_from[1]])
      end
    end
    if @checked
      moves_to_choose = moves_under_check
      avail_moves &= moves_to_choose
    end
    return avail_moves if limited_region == []
    avail_moves &= limited_region
    avail_moves
  end
  def checking_route_rook(pos_from)
    avail_moves = []
    (pos_from[1] - 1).downto(1) do |i| # West branch, (5,4) - 5,3 - 5,2 - 5,1
      avail_moves.push([pos_from[0], i])
      break if @board[pos_from[0]][i] != '  '
    end
    return avail_moves if @board[pos_from[0]][pos_from[1]][1] == 'B' && avail_moves.include?(@white_king_pos[0])
    return avail_moves if @board[pos_from[0]][pos_from[1]][1] == 'W' && avail_moves.include?(@black_king_pos[0])
    avail_moves = []
    (pos_from[0] - 1).downto(1) do |i|   # North branch, (5,4) - 4,4 - 3,4 - 2,4 - 1,4
      avail_moves.push([i, pos_from[1]])
      break if @board[i][pos_from[1]] != '  '
    end
    return avail_moves if @board[pos_from[0]][pos_from[1]][1] == 'B' && avail_moves.include?(@white_king_pos[0])
    return avail_moves if @board[pos_from[0]][pos_from[1]][1] == 'W' && avail_moves.include?(@black_king_pos[0])
    avail_moves = []
    ((pos_from[1] + 1)..8).each do |i|   # East branch, (5,4) - 5,5 - 5,6 - 5,7 - 5,8
      avail_moves.push([pos_from[0], i])
      break if @board[pos_from[0]][i] != '  '
    end
    return avail_moves if @board[pos_from[0]][pos_from[1]][1] == 'B' && avail_moves.include?(@white_king_pos[0])
    return avail_moves if @board[pos_from[0]][pos_from[1]][1] == 'W' && avail_moves.include?(@black_king_pos[0])
    avail_moves = []
    ((pos_from[0] + 1)..8).each do |i|   # South branch, (5,4) - 6,4 - 7,4 - 8,4
      avail_moves.push([i, pos_from[1]])
      break if @board[i][pos_from[1]] != '  '
    end
    return avail_moves if @board[pos_from[0]][pos_from[1]][1] == 'B' && avail_moves.include?(@white_king_pos[0])
    return avail_moves if @board[pos_from[0]][pos_from[1]][1] == 'W' && avail_moves.include?(@black_king_pos[0])
    avail_moves = []
    avail_moves
  end
  def checking_route_rook_all(pos_from)
    avail_moves = []
    (pos_from[1] - 1).downto(1) do |i| # West branch, (5,4) - 5,3 - 5,2 - 5,1
      avail_moves.push([pos_from[0], i])
      break if @board[pos_from[0]][i] != '  '
    end
    (pos_from[0] - 1).downto(1) do |i|   # North branch, (5,4) - 4,4 - 3,4 - 2,4 - 1,4
      avail_moves.push([i, pos_from[1]])
      break if @board[i][pos_from[1]] != '  '
    end
    ((pos_from[1] + 1)..8).each do |i|   # East branch, (5,4) - 5,5 - 5,6 - 5,7 - 5,8
      avail_moves.push([pos_from[0], i])
      break if @board[pos_from[0]][i] != '  '
    end
    ((pos_from[0] + 1)..8).each do |i|   # South branch, (5,4) - 6,4 - 7,4 - 8,4
      avail_moves.push([i, pos_from[1]])
      break if @board[i][pos_from[1]] != '  '
    end
    avail_moves
  end
  def available_moves_bishop(pos_from)
    avail_moves = []
    piece_container = @board[pos_from[0]][pos_from[1]]
    @board[pos_from[0]][pos_from[1]] = '  '
    limited_region = moves_under_check
    @board[pos_from[0]][pos_from[1]] = piece_container
    if pos_from[0] >= pos_from[1]
      smallfigure = pos_from[1] - 1
      bigfigure = pos_from[0]
    else
      smallfigure = pos_from[0] - 1
      bigfigure = pos_from[1]
    end
    (1..smallfigure).each do |i| # NW, (5,4) - 4,3 - 3,2 - 2,1 smaller
      if @board[pos_from[0] - i][pos_from[1] - i] != '  '
        if @board[pos_from[0] - i][pos_from[1] - i][1] != @board[pos_from[0]][pos_from[1]][1]
          avail_moves.push([pos_from[0] - i, pos_from[1] - i])
        end
        break
      else
        avail_moves.push([pos_from[0] - i, pos_from[1] - i])
      end
    end
    if pos_from[0] - 1 >= 8 - pos_from[1] # NE, (5,5) - 4,6 - 3,7 - 2,8
      (1..(8 - pos_from[1])).each do |i|
        if @board[pos_from[0] - i][pos_from[1] + i] != '  '
          if @board[pos_from[0] - i][pos_from[1] + i][1] != @board[pos_from[0]][pos_from[1]][1]
            avail_moves.push([pos_from[0] - i, pos_from[1] + i])
          end
          break
        else
          avail_moves.push([pos_from[0] - i, pos_from[1] + i])
        end
      end
    else
      (1..(pos_from[0] - 1)).each do |i|
        if @board[pos_from[0] - i][pos_from[1] + i] != '  '
          if @board[pos_from[0] - i][pos_from[1] + i][1] != @board[pos_from[0]][pos_from[1]][1]
            avail_moves.push([pos_from[0] - i, pos_from[1] + i])
          end
          break
        else
          avail_moves.push([pos_from[0] - i, pos_from[1] + i])
        end
      end
    end
    if 8 - pos_from[0] >= pos_from[1] - 1 # SW, (5,4) - 6,3 - 7,2 - 8,1
      (1..(pos_from[1] - 1)).each do |i|
        if @board[pos_from[0] + i][pos_from[1] - i] != '  '
          if @board[pos_from[0] + i][pos_from[1] - i][1] != @board[pos_from[0]][pos_from[1]][1]
            avail_moves.push([pos_from[0] + i, pos_from[1] - i])
          end
          break
        else
          avail_moves.push([pos_from[0] + i, pos_from[1] - i])
        end
      end
    else
      (1..(8 - pos_from[0])).each do |i|
        if @board[pos_from[0] + i][pos_from[1] - i] != '  '
          if @board[pos_from[0] + i][pos_from[1] - i][1] != @board[pos_from[0]][pos_from[1]][1]
            avail_moves.push([pos_from[0] + i, pos_from[1] - i])
          end
          break
        else
          avail_moves.push([pos_from[0] + i, pos_from[1] - i])
        end
      end
    end
    (1..(8 - bigfigure)).each do |i| # SE, (5,4) - 6,5 - 7,6 - 8,7 bigger
      if @board[pos_from[0] + i][pos_from[1] + i] != '  '
        if @board[pos_from[0] + i][pos_from[1] + i][1] != @board[pos_from[0]][pos_from[1]][1]
          avail_moves.push([pos_from[0] + i, pos_from[1] + i])
        end
        break
      else
        avail_moves.push([pos_from[0] + i, pos_from[1] + i])
      end
    end
    if @checked
      moves_to_choose = moves_under_check
      avail_moves &= moves_to_choose
    end
    return avail_moves if limited_region == []
    avail_moves &= limited_region
    avail_moves
  end
  def checking_route_bishop(pos_from)
    avail_moves = []
    if pos_from[0] >= pos_from[1]
      smallfigure = pos_from[1] - 1
      bigfigure = pos_from[0]
    else
      smallfigure = pos_from[0] - 1
      bigfigure = pos_from[1]
    end
    (1..smallfigure).each do |i| # NW, (5,4) - 4,3 - 3,2 - 2,1 smaller
      avail_moves.push([pos_from[0] - i, pos_from[1] - i])
      break if @board[pos_from[0] - i][pos_from[1] - i] != '  '
    end
    return avail_moves if @board[pos_from[0]][pos_from[1]][1] == 'B' && avail_moves.include?(@white_king_pos[0])
    return avail_moves if @board[pos_from[0]][pos_from[1]][1] == 'W' && avail_moves.include?(@black_king_pos[0])
    avail_moves = []
    if pos_from[0] - 1 >= 8 - pos_from[1] # NE, (5,5) - 4,6 - 3,7 - 2,8
      (1..(8 - pos_from[1])).each do |i|
        avail_moves.push([pos_from[0] - i, pos_from[1] + i])
        break if @board[pos_from[0] - i][pos_from[1] + i] != '  '
      end
    else
      (1..(pos_from[0] - 1)).each do |i|
        avail_moves.push([pos_from[0] - i, pos_from[1] + i])
        break if @board[pos_from[0] - i][pos_from[1] + i] != '  '
      end
    end
    return avail_moves if @board[pos_from[0]][pos_from[1]][1] == 'B' && avail_moves.include?(@white_king_pos[0])
    return avail_moves if @board[pos_from[0]][pos_from[1]][1] == 'W' && avail_moves.include?(@black_king_pos[0])
    avail_moves = []
    if 8 - pos_from[0] >= pos_from[1] - 1 # SW, (5,4) - 6,3 - 7,2 - 8,1
      (1..(pos_from[1] - 1)).each do |i|
        avail_moves.push([pos_from[0] + i, pos_from[1] - i])
        break if @board[pos_from[0] + i][pos_from[1] - i] != '  '
      end
    else
      (1..(8 - pos_from[0])).each do |i|
        avail_moves.push([pos_from[0] + i, pos_from[1] - i])
        break if @board[pos_from[0] + i][pos_from[1] - i] != '  '
      end
    end
    return avail_moves if @board[pos_from[0]][pos_from[1]][1] == 'B' && avail_moves.include?(@white_king_pos[0])
    return avail_moves if @board[pos_from[0]][pos_from[1]][1] == 'W' && avail_moves.include?(@black_king_pos[0])
    avail_moves = []
    (1..(8 - bigfigure)).each do |i| # SE, (5,4) - 6,5 - 7,6 - 8,7 bigger
      avail_moves.push([pos_from[0] + i, pos_from[1] + i])
      break if @board[pos_from[0] + i][pos_from[1] + i] != '  '
    end
    return avail_moves if @board[pos_from[0]][pos_from[1]][1] == 'B' && avail_moves.include?(@white_king_pos[0])
    return avail_moves if @board[pos_from[0]][pos_from[1]][1] == 'W' && avail_moves.include?(@black_king_pos[0])
    avail_moves = []
  end
  def checking_route_bishop_all(pos_from)
    avail_moves = []
    if pos_from[0] >= pos_from[1]
      smallfigure = pos_from[1] - 1
      bigfigure = pos_from[0]
    else
      smallfigure = pos_from[0] - 1
      bigfigure = pos_from[1]
    end
    (1..smallfigure).each do |i| # NW, (5,4) - 4,3 - 3,2 - 2,1 smaller
      avail_moves.push([pos_from[0] - i, pos_from[1] - i])
      break if @board[pos_from[0] - i][pos_from[1] - i] != '  '
    end
    if pos_from[0] - 1 >= 8 - pos_from[1] # NE, (5,5) - 4,6 - 3,7 - 2,8
      (1..(8 - pos_from[1])).each do |i|
        avail_moves.push([pos_from[0] - i, pos_from[1] + i])
        break if @board[pos_from[0] - i][pos_from[1] + i] != '  '
      end
    else
      (1..(pos_from[0] - 1)).each do |i|
        avail_moves.push([pos_from[0] - i, pos_from[1] + i]) 
        break if @board[pos_from[0] - i][pos_from[1] + i] != '  '
      end
    end
    if 8 - pos_from[0] >= pos_from[1] - 1 # SW, (5,4) - 6,3 - 7,2 - 8,1
      (1..(pos_from[1] - 1)).each do |i|
        avail_moves.push([pos_from[0] + i, pos_from[1] - i]) 
        break if @board[pos_from[0] + i][pos_from[1] - i] != '  '
      end
    else
      (1..(8 - pos_from[0])).each do |i|
        avail_moves.push([pos_from[0] + i, pos_from[1] - i])
        break if @board[pos_from[0] + i][pos_from[1] - i] != '  '
      end
    end
    (1..(8 - bigfigure)).each do |i| # SE, (5,4) - 6,5 - 7,6 - 8,7 bigger
      avail_moves.push([pos_from[0] + i, pos_from[1] + i])
      break if @board[pos_from[0] + i][pos_from[1] + i] != '  '
    end
    avail_moves
  end
  def available_moves_queen(pos_from) # Basically rook + bishop
    avail_moves = []
    piece_container = @board[pos_from[0]][pos_from[1]]
    @board[pos_from[0]][pos_from[1]] = '  '
    limited_region = moves_under_check
    @board[pos_from[0]][pos_from[1]] = piece_container
    avail_moves1 = available_moves_rook(pos_from)
    avail_moves2 = available_moves_bishop(pos_from)
    avail_moves1.each do |move|
      avail_moves.push(move)
    end
    avail_moves2.each do |move|
      avail_moves.push(move)
    end
    if @checked
      moves_to_choose = moves_under_check
      avail_moves &= moves_to_choose
    end
    return avail_moves if limited_region == []
    avail_moves &= limited_region
    avail_moves
  end
  def checking_route_queen(pos_from)
    avail_moves = []
    avail_moves1 = checking_route_rook(pos_from)
    avail_moves2 = checking_route_bishop(pos_from)
    unless avail_moves1 == []
      avail_moves1.each do |move|
        avail_moves.push(move)
      end
    end
    unless avail_moves2 == []
      avail_moves2.each do |move|
        avail_moves.push(move)
      end
    end
    avail_moves
  end
  def checking_route_queen_all(pos_from)
    avail_moves = []
    avail_moves1 = checking_route_rook_all(pos_from)
    avail_moves2 = checking_route_bishop_all(pos_from)
    unless avail_moves1 == []
      avail_moves1.each do |move|
        avail_moves.push(move)
      end
    end
    unless avail_moves2 == []
      avail_moves2.each do |move|
        avail_moves.push(move)
      end
    end
    avail_moves
  end
  def available_moves_knight(pos_from)
    avail_moves = []
    piece_container = @board[pos_from[0]][pos_from[1]]
    @board[pos_from[0]][pos_from[1]] = '  '
    limited_region = moves_under_check
    @board[pos_from[0]][pos_from[1]] = piece_container
    if pos_from[0] + 2 <= 8 && pos_from[1] + 1 <= 8 && @board[pos_from[0] + 2][pos_from[1] + 1][1] != @board[pos_from[0]][pos_from[1]][1]
      avail_moves.push([pos_from[0] + 2, pos_from[1] + 1])
    end
    if pos_from[0] + 2 <= 8 && pos_from[1] - 1 >= 1 && @board[pos_from[0] + 2][pos_from[1] - 1][1] != @board[pos_from[0]][pos_from[1]][1]
      avail_moves.push([pos_from[0] + 2, pos_from[1] - 1])
    end
    if pos_from[0] - 2 >= 1 && pos_from[1] + 1 <= 8 && @board[pos_from[0] - 2][pos_from[1] + 1][1] != @board[pos_from[0]][pos_from[1]][1]
      avail_moves.push([pos_from[0] - 2, pos_from[1] + 1])
    end
    if pos_from[0] - 2 >= 1 && pos_from[1] - 1 >= 1 && @board[pos_from[0] - 2][pos_from[1] - 1][1] != @board[pos_from[0]][pos_from[1]][1]
      avail_moves.push([pos_from[0] - 2, pos_from[1] - 1])
    end
    if pos_from[0] + 1 <= 8 && pos_from[1] + 2 <= 8 && @board[pos_from[0] + 1][pos_from[1] + 2][1] != @board[pos_from[0]][pos_from[1]][1]
      avail_moves.push([pos_from[0] + 1, pos_from[1] + 2])
    end
    if pos_from[0] + 1 <= 8 && pos_from[1] - 2 >= 1 && @board[pos_from[0] + 1][pos_from[1] - 2][1] != @board[pos_from[0]][pos_from[1]][1]
      avail_moves.push([pos_from[0] + 1, pos_from[1] - 2])
    end
    if pos_from[0] - 1 >= 1 && pos_from[1] + 2 <= 8 && @board[pos_from[0] - 1][pos_from[1] + 2][1] != @board[pos_from[0]][pos_from[1]][1]
      avail_moves.push([pos_from[0] - 1, pos_from[1] + 2])
    end
    if pos_from[0] - 1 >= 1 && pos_from[1] - 2 >= 1 && @board[pos_from[0] - 1][pos_from[1] - 2][1] != @board[pos_from[0]][pos_from[1]][1]
      avail_moves.push([pos_from[0] - 1, pos_from[1] - 2])
    end
    if @checked
      moves_to_choose = moves_under_check
      avail_moves &= moves_to_choose
    end
    return avail_moves if limited_region == []
    avail_moves &= limited_region
    avail_moves
  end
  def checking_route_knight(pos_from)
    avail_moves = []
    if pos_from[0] + 2 <= 8 && pos_from[1] + 1 <= 8 #&& @board[pos_from[0] + 2][pos_from[1] + 1][1] != @board[pos_from[0]][pos_from[1]][1]
      avail_moves.push([pos_from[0] + 2, pos_from[1] + 1])
    end
    if pos_from[0] + 2 <= 8 && pos_from[1] - 1 >= 1 #&& @board[pos_from[0] + 2][pos_from[1] - 1][1] != @board[pos_from[0]][pos_from[1]][1]
      avail_moves.push([pos_from[0] + 2, pos_from[1] - 1])
    end
    if pos_from[0] - 2 >= 1 && pos_from[1] + 1 <= 8 #&& @board[pos_from[0] - 2][pos_from[1] + 1][1] != @board[pos_from[0]][pos_from[1]][1]
      avail_moves.push([pos_from[0] - 2, pos_from[1] + 1])
    end
    if pos_from[0] - 2 >= 1 && pos_from[1] - 1 >= 1 #&& @board[pos_from[0] - 2][pos_from[1] - 1][1] != @board[pos_from[0]][pos_from[1]][1]
      avail_moves.push([pos_from[0] - 2, pos_from[1] - 1])
    end
    if pos_from[0] + 1 <= 8 && pos_from[1] + 2 <= 8 #&& @board[pos_from[0] + 1][pos_from[1] + 2][1] != @board[pos_from[0]][pos_from[1]][1]
      avail_moves.push([pos_from[0] + 1, pos_from[1] + 2])
    end
    if pos_from[0] + 1 <= 8 && pos_from[1] - 2 >= 1 #&& @board[pos_from[0] + 1][pos_from[1] - 2][1] != @board[pos_from[0]][pos_from[1]][1]
      avail_moves.push([pos_from[0] + 1, pos_from[1] - 2])
    end
    if pos_from[0] - 1 >= 1 && pos_from[1] + 2 <= 8 #&& @board[pos_from[0] - 1][pos_from[1] + 2][1] != @board[pos_from[0]][pos_from[1]][1]
      avail_moves.push([pos_from[0] - 1, pos_from[1] + 2])
    end
    if pos_from[0] - 1 >= 1 && pos_from[1] - 2 >= 1 #&& @board[pos_from[0] - 1][pos_from[1] - 2][1] != @board[pos_from[0]][pos_from[1]][1]
      avail_moves.push([pos_from[0] - 1, pos_from[1] - 2])
    end
    avail_moves
  end
  def available_moves_pawn(pos_from)
    avail_moves = []
    piece_container = @board[pos_from[0]][pos_from[1]]
    @board[pos_from[0]][pos_from[1]] = '  '
    limited_region = moves_under_check
    @board[pos_from[0]][pos_from[1]] = piece_container
    if @board[pos_from[0]][pos_from[1]] == 'PW' && pos_from[0] == 7 &&
       @board[pos_from[0] - 1][pos_from[1]] == '  ' && @board[pos_from[0] - 2][pos_from[1]] == '  '
      avail_moves.push([pos_from[0] - 2, pos_from[1]])  #first move two squares
    elsif @board[pos_from[0]][pos_from[1]] == 'PB' && pos_from[0] == 2 &&
          @board[pos_from[0] + 1][pos_from[1]] == '  ' && @board[pos_from[0] + 2][pos_from[1]] == '  '
      avail_moves.push([pos_from[0] + 2, pos_from[1]])
    end
    if @board[pos_from[0]][pos_from[1]] == 'PW' && pos_from[1] - 1 >= 1 && @board[pos_from[0] - 1][pos_from[1] - 1][1] == 'B'
      avail_moves.push([pos_from[0] - 1, pos_from[1] - 1])
    elsif @board[pos_from[0]][pos_from[1]] == 'PB' && pos_from[1] - 1 >= 1 && @board[pos_from[0] + 1][pos_from[1] - 1][1] == 'W'
      avail_moves.push([pos_from[0] + 1, pos_from[1] - 1])
    end
    if @board[pos_from[0]][pos_from[1]] == 'PW' && pos_from[1] + 1 <= 8 && @board[pos_from[0] - 1][pos_from[1] + 1][1] == 'B'
      avail_moves.push([pos_from[0] - 1, pos_from[1] + 1])
    elsif @board[pos_from[0]][pos_from[1]] == 'PB' && pos_from[1] + 1 <= 8 && @board[pos_from[0] + 1][pos_from[1] + 1][1] == 'W'
      avail_moves.push([pos_from[0] + 1, pos_from[1] + 1])
    end
    if @board[pos_from[0]][pos_from[1]] == 'PW' && @board[pos_from[0] - 1][pos_from[1]] == '  '
      avail_moves.push([pos_from[0] - 1, pos_from[1]])
    elsif @board[pos_from[0]][pos_from[1]] == 'PB' && @board[pos_from[0] + 1][pos_from[1]] == '  '
      avail_moves.push([pos_from[0] + 1, pos_from[1]])
    end
    if @board[pos_from[0]][pos_from[1]] == 'PW' && pos_from[0] == 4 && @last_move[0] == 'PB' &&
       @last_move[1][0] == 2 && @last_move[2][0] == 4
      if @last_move[2][1] == pos_from[1] + 1
        avail_moves.push([pos_from[0] - 1, pos_from[1] + 1])    # En passant
      elsif @last_move[2][1] == pos_from[1] - 1
        avail_moves.push([pos_from[0] - 1, pos_from[1] - 1])
      end
      @enpassant = true
    elsif @board[pos_from[0]][pos_from[1]] == 'PB' && pos_from[0] == 5 && @last_move[0] == 'PW' &&
          @last_move[1][0] == 7 && @last_move[2][0] == 5
      if @last_move[2][1] == pos_from[1] + 1
        avail_moves.push([pos_from[0] + 1, pos_from[1] + 1])    # En passant
      elsif @last_move[2][1] == @pos_from[1] - 1
        avail_moves.push([pos_from[0] + 1, pos_from[1] - 1])
      end
      @enpassant = true
    end
    if @checked
      moves_to_choose = moves_under_check
      avail_moves &= moves_to_choose
    end
    return avail_moves if limited_region == []
    avail_moves &= limited_region
    avail_moves
  end
  def checking_route_pawn(pos_from)
    avail_moves = []
    if @board[pos_from[0]][pos_from[1]] == 'PW' && pos_from[1] - 1 >= 1 && pos_from[0] - 1 >= 1 #&& @board[pos_from[0] - 1][pos_from[1] - 1][1] == 'B'
      avail_moves.push([pos_from[0] - 1, pos_from[1] - 1])
    elsif @board[pos_from[0]][pos_from[1]] == 'PB' && pos_from[1] - 1 >= 1 && pos_from[0] + 1 <= 8 #&& @board[pos_from[0] + 1][pos_from[1] - 1][1] == 'W'
      avail_moves.push([pos_from[0] + 1, pos_from[1] - 1])
    end
    if @board[pos_from[0]][pos_from[1]] == 'PW' && pos_from[1] + 1 <= 8 && pos_from[0] - 1 >= 1 #&& @board[pos_from[0] - 1][pos_from[1] + 1][1] == 'B' 
      avail_moves.push([pos_from[0] - 1, pos_from[1] + 1])
    elsif @board[pos_from[0]][pos_from[1]] == 'PB' && pos_from[1] + 1 <= 8 && pos_from[0] + 1 <= 8 #&& @board[pos_from[0] + 1][pos_from[1] + 1][1] == 'W'
      avail_moves.push([pos_from[0] + 1, pos_from[1] + 1])
    end
    avail_moves
  end
  def en_passant_check
    return unless @enpassant
    @board[@last_move[2][0]][@last_move[2][1]] = '  ' if @pos_to[1] == @last_move[2][1]
    @enpassant = false
  end
  def available_moves_king(pos_from)
    avail_moves = []
    piece_container = @board[pos_from[0]][pos_from[1]]
    @board[pos_from[0]][pos_from[1]] = '  '
    squares_reaches = all_squares_reachedv2
    @board[pos_from[0]][pos_from[1]] = piece_container
    if pos_from[0] - 1 >= 1 && @board[pos_from[0] - 1][pos_from[1]][1] != @board[pos_from[0]][pos_from[1]][1] &&
       squares_reaches.include?([pos_from[0] - 1, pos_from[1]]) == false
      avail_moves.push([pos_from[0] - 1, pos_from[1]])
    end
    if pos_from[0] - 1 >= 1 && pos_from[1] + 1 <= 8 && @board[pos_from[0] - 1][pos_from[1] + 1][1] != @board[pos_from[0]][pos_from[1]][1] &&
       squares_reaches.include?([pos_from[0] - 1, pos_from[1] + 1]) == false
      avail_moves.push([pos_from[0] - 1, pos_from[1] + 1])
    end
    if pos_from[1] + 1 <= 8 && (@board[pos_from[0]][pos_from[1] + 1][1] != @board[pos_from[0]][pos_from[1]][1]) &&
       (squares_reaches.include?([pos_from[0], pos_from[1] + 1]) == false)
      avail_moves.push([pos_from[0], pos_from[1] + 1])
    end
    if pos_from[0] + 1 <= 8 && pos_from[1] + 1 <= 8 && @board[pos_from[0] + 1][pos_from[1] + 1][1] != @board[pos_from[0]][pos_from[1]][1] &&
       squares_reaches.include?([pos_from[0] + 1, pos_from[1] + 1]) == false
      avail_moves.push([pos_from[0] + 1, pos_from[1] + 1])
    end
    if pos_from[0] + 1 <= 8 && @board[pos_from[0] + 1][pos_from[1]][1] != @board[pos_from[0]][pos_from[1]][1] &&
       squares_reaches.include?([pos_from[0] + 1, pos_from[1]]) == false
      avail_moves.push([pos_from[0] + 1, pos_from[1]])
    end
    if pos_from[0] + 1 <= 8 && pos_from[1] - 1 >= 1 && @board[pos_from[0] + 1][pos_from[1] - 1][1] != @board[pos_from[0]][pos_from[1]][1] && 
       squares_reaches.include?([pos_from[0] + 1, pos_from[1] - 1]) == false
      avail_moves.push([pos_from[0] + 1, pos_from[1] - 1])
    end
    if pos_from[1] - 1 >= 1 && @board[pos_from[0]][pos_from[1] - 1][1] != @board[pos_from[0]][@pos_from[1]][1] &&
       squares_reaches.include?([pos_from[0], pos_from[1] - 1]) == false
      avail_moves.push([pos_from[0], pos_from[1] - 1])
    end
    if pos_from[0] - 1 >= 1 && pos_from[1] - 1 >= 1 && @board[pos_from[0] - 1][pos_from[1] - 1][1] != @board[pos_from[0]][pos_from[1]][1] &&
       squares_reaches.include?([pos_from[0] - 1, pos_from[1] - 1]) == false
      avail_moves.push([pos_from[0] - 1, pos_from[1] - 1])
    end
    if @colour == 'W' && @white_king_pos[1] == false && @board[8][5] == 'KW' &&
       @wrook_right_route == [false, false] && @board[8][6] == '  ' && @board[8][7] == '  '
      avail_moves.push([8, 7])
    end
    if @colour == 'W' && @white_king_pos[1] == false && @board[8][5] == 'KW' &&
       @wrook_left_route == [false, false] && @board[8][4] == '  ' && @board[8][3] == '  '
      avail_moves.push([8, 3])
    end
    if @colour == 'B' && @black_king_pos[1] == false && @board[1][5] == 'KB' &&
       @brook_right_route == [false, false] && @board[1][6] == '  ' && @board[1][7] == '  '
      avail_moves.push([1, 7])
    end
    if @colour == 'B' && @black_king_pos[1] == false && @board[1][5] == 'KB' &&
       @brook_left_route == [false, false] && @board[1][4] == '  ' && @board[1][3] == '  '
      avail_moves.push([1, 3])
    end
    avail_moves
  end
  def checking_route_king(pos_from)
    avail_moves = []
    avail_moves.push([pos_from[0] - 1, pos_from[1]]) if pos_from[0] - 1 >= 1 #&& @board[pos_from[0] - 1][pos_from[1]][1] != @board[pos_from[0]][pos_from[1]][1]
    avail_moves.push([pos_from[0] - 1, pos_from[1] + 1]) if pos_from[0] - 1 >= 1 && pos_from[1] + 1 <= 8 #&& @board[pos_from[0] - 1][pos_from[1] + 1][1] != @board[pos_from[0]][pos_from[1]][1]
    avail_moves.push([pos_from[0], pos_from[1] + 1]) if pos_from[1] + 1 <= 8 #&& @board[pos_from[0]][pos_from[1] + 1][1] != @board[pos_from[0]][pos_from[1]][1]
    avail_moves.push([pos_from[0] + 1, pos_from[1] + 1]) if pos_from[0] + 1 <= 8 && pos_from[1] + 1 <= 8 #&& @board[pos_from[0] + 1][pos_from[1] + 1][1] != @board[pos_from[0]][pos_from[1]][1]
    avail_moves.push([pos_from[0] + 1, pos_from[1]]) if pos_from[0] + 1 <= 8 #&& @board[pos_from[0] + 1][pos_from[1]][1] != @board[pos_from[0]][pos_from[1]][1]
    avail_moves.push([pos_from[0] - 1, pos_from[1] + 1]) if pos_from[0] + 1 <= 8 && pos_from[1] - 1 >= 1 #&& @board[pos_from[0] + 1][pos_from[1] - 1][1] != @board[pos_from[0]][pos_from[1]][1]
    avail_moves.push([pos_from[0], pos_from[1] - 1]) if pos_from[1] - 1 >= 1 # && @board[pos_from[0]][pos_from[1] - 1][1] != @board[pos_from[0]][@pos_from[1]][1]
    avail_moves.push([pos_from[0] - 1, pos_from[1] - 1]) if pos_from[0] - 1 >= 1 && pos_from[1] - 1 >= 1 #&& @board[pos_from[0] - 1][pos_from[1] - 1][1] != @board[pos_from[0]][pos_from[1]][1]
    avail_moves
  end
  def full_name(name)
    case name
    when 'P'
      'pawn'
    when 'N'
      'knight'
    when 'B'
      'bishop'
    when 'K'
      'king'
    when 'Q'
      'queen'
    when 'R'
      'rook'
    end
  end
  def colour_name(name)
    case name
    when 'B'
      'black'
    when 'W'
      'white'
    end
  end
  def promotion?
    return unless @piece[0] == 'P' && (@pos_to[0] == 1 || @pos_to[0] == 8)
    choices = %w[Q N B R]
    promo_choice = nil
    loop do
      print 'Which piece to promote to? (Q, N, B, R) '
      promo_choice = gets.chomp.upcase
      redo unless choices.include?(promo_choice)
      break
    end
    @board[@pos_to[0]][@pos_to[1]][0] = promo_choice
  end
  def new_king_pos
    case @piece
    when 'KW'
      @white_king_pos = [@pos_to, true]
    when 'KB'
      @black_king_pos = [@pos_to, true]
    end
  end
  def all_squares_reached # Get all squares that may be checking opponent king
    @all_squares_reaches = []
    @board.each_with_index do |rank, row| # file is already the content
      rank.each_with_index do |file, column| # 1,1 - 1,2 - 1,3 ...
        next if row.zero? || column.zero? || file == '  '
        next if @colour == 'W' && file[1] == 'B' # White checks black
        next if @colour == 'B' && file[1] == 'W' # Black checks white
        case file[0]
        when 'R'
          avail_moves = checking_route_rook_all([row, column])
        when 'N'
          avail_moves = checking_route_knight([row, column])
        when 'B'
          avail_moves = checking_route_bishop_all([row, column])
        when 'Q'
          avail_moves = checking_route_queen_all([row, column])
        when 'K'
          avail_moves = checking_route_king([row, column])
        when 'P'
          avail_moves = checking_route_pawn([row, column])
        end
        avail_moves.each do |move|
          @all_squares_reaches.push(move)
        end
      end
    end
    @all_squares_reaches.uniq
  end
  def all_squares_reachedv2 # Get all squares that can be reached by opponent pieces
    all_squares_reaches = []
    @board.each_with_index do |rank, row| # file is already the content
      rank.each_with_index do |file, column| # 1,1 - 1,2 - 1,3 ...
        next if row.zero? || column.zero? || file == '  '
        next if @colour == 'W' && file[1] == 'W' # White checks black
        next if @colour == 'B' && file[1] == 'B' # Black checks white
        case file[0]
        when 'R'
          avail_moves = checking_route_rook_all([row, column])
        when 'N'
          avail_moves = checking_route_knight([row, column])
        when 'B'
          avail_moves = checking_route_bishop_all([row, column])
        when 'Q'
          avail_moves = checking_route_queen_all([row, column])
        when 'K'
          avail_moves = checking_route_king([row, column])
        when 'P'
          avail_moves = checking_route_pawn([row, column])
        end
        avail_moves.each do |move|
          all_squares_reaches.push(move)
        end
      end
    end
    all_squares_reaches.uniq
  end
  def rook_pos_check
    if board[8][8] == '  '
      @wrook_right_route[0] = true
    elsif board[8][1] == '  '
      @wrook_left_route[0] = true
    elsif board[1][8] == '  '
      @brook_right_route[0] = true
    elsif board[1][1] == '  '
      @brook_left_route[0] = true
    end
  end
  def checked?
    all_avail_moves = @all_squares_reaches
    if (@colour == 'W' && all_avail_moves.include?(@black_king_pos[0])) ||
       (@colour == 'B' && all_avail_moves.include?(@white_king_pos[0]))
      @checked = true
    else
      @checked = false
    end
  end
  def castle_right
    all_avail_moves = @all_squares_reaches
    if @colour == 'W' && (all_avail_moves.include?([1, 6]) || all_avail_moves.include?([1, 7]) || all_avail_moves.include?([1, 5]))
      @brook_right_route[1] = true
    elsif @colour == 'W'
      @brook_right_route[1] = false
    end
    if @colour == 'W' && (all_avail_moves.include?([1, 4]) || all_avail_moves.include?([1, 3]) || all_avail_moves.include?([1, 5]))
      @brook_left_route[1] = true
    elsif @colour == 'W'
      @brook_left_route[1] = false
    end
    if @colour == 'B' && (all_avail_moves.include?([8, 4]) || all_avail_moves.include?([8, 3]) || all_avail_moves.include?([8, 5]))
      @wrook_left_route[1] = true
    elsif @colour == 'B'
      @wrook_left_route[1] = false
    end
    if @colour == 'B' && (all_avail_moves.include?([8, 6]) || all_avail_moves.include?([8, 7]) || all_avail_moves.include?([8, 5]))
      @wrook_right_route[1] = true
    elsif @colour == 'B'
      @wrook_right_route[1] = false
    end
  end
  def castling
    if @piece == 'KW' && @pos_from == [8, 5] && @pos_to == [8, 7]
      @board[8][8] = '  '
      @board[8][6] = 'RW'
    elsif @piece == 'KW' && @pos_from == [8, 5] && @pos_to == [8, 3]
      @board[8][1] = '  '
      @board[8][4] = 'RW'
    elsif @piece == 'KB' && @pos_from == [1, 5] && @pos_to == [1, 3]
      @board[1][1] = '  '
      @board[1][4] = 'RB'
    elsif @piece == 'KB' && @pos_from == [1, 5] && @pos_to == [1, 7]
      @board[1][8] = '  '
      @board[1][6] = 'RB'
    end
  end
  def moves_under_check  # Get moves available for non-king to defend a check
    all_avail_moves = []
    @mate_counter = 0
    @board.each_with_index do |rank, row| # file is already the content
      rank.each_with_index do |file, column| # 1,1 - 1,2 - 1,3 ...
        next if row.zero? || column.zero? || file == '  ' || file[0] == 'K'
        next if @colour == 'W' && file[1] == 'W' # White checks black
        next if @colour == 'B' && file[1] == 'B' # Black checks white
        avail_moves = []
        case file[0]
        when 'R'
          avail_moves = checking_route_rook([row, column])
        when 'N'
          avail_moves = checking_route_knight([row, column])
        when 'B'
          avail_moves = checking_route_bishop([row, column])
        when 'Q'
          avail_moves = checking_route_queen([row, column])
        when 'P'
          avail_moves = checking_route_pawn([row, column])
        end
        next if avail_moves == [] || (@colour == 'W' && avail_moves.include?(@white_king_pos[0]) == false) ||
                (@colour == 'B' && avail_moves.include?(@black_king_pos[0]) == false)
        if file[0] == 'R' || file[0] == 'B' || file[0] == 'Q'
          avail_moves.each do |move|
            all_avail_moves.push(move)
          end
        end
        all_avail_moves.push([row, column])
        @mate_counter += 1
        if @colour == 'W'
          all_avail_moves.delete(@white_king_pos[0])
        elsif @colour == 'B'
          all_avail_moves.delete(@black_king_pos[0])
        end
      end
    end
    all_avail_moves.uniq
  end
  def checkmate_loop # if non king pieces can not cover check route, then true
    all_squares_reaches = []
    @board.each_with_index do |rank, row| # file is already the content
      rank.each_with_index do |file, column| # 1,1 - 1,2 - 1,3 ...
        next if row.zero? || column.zero? || file == '  ' || file[0] == 'K'
        next if @colour == 'W' && file[1] == 'B' # White checks black
        next if @colour == 'B' && file[1] == 'W' # Black checks white
        case file[0]
        when 'R'
          avail_moves = available_moves_rook([row, column])
        when 'N'
          avail_moves = available_moves_knight([row, column])
        when 'B'
          avail_moves = available_moves_bishop([row, column])
        when 'Q'
          avail_moves = available_moves_queen([row, column])
        when 'P'
          avail_moves = available_moves_pawn([row, column])
        end
        next if avail_moves == []
        avail_moves.each do |move|
          all_squares_reaches.push(move)
        end
      end
    end
    return true if all_squares_reaches & moves_under_check == []
    false
  end
end

chess = Chess.new
chess.game
