class Pokemon
  def initialize
    @all_pattern = Array.new
    32.times do |i|
      32.times do |j|
        32.times do |k|
          arr = [31, 31, 31, i, j, k]
          arr.permutation(6) do |h, a, b, c, d, s|
            @all_pattern << [h, a, b, c, d, s]
          end
        end
      end
    end
    puts 'pattern difined'

    @selected_pattern = @all_pattern.select do |arr|
      arr[0] >= 30 && arr[5] >= 30
    end
    puts 'pattern selected'

    @match_pattern = @selected_pattern.select do |arr|
      ( arr[0] == 30 &&
        arr[2] == 30 &&
        arr[3] == 31 &&
        arr[4] == 31 &&
        arr[5] == 31
      ) ||
      ( arr[0] == 31 &&
        arr[1].even? &&
        arr[2] == 30 &&
        arr[3] == 31 &&
        arr[4].even? &&
        arr[5] == 31
        )
    end

    @result_1 = @match_pattern.select do |arr|
      arr[0] == 30 &&
      arr[2] == 30 &&
      arr[3] == 31 &&
      arr[4] == 31 &&
      arr[5] == 31
    end
    @result_2 = @match_pattern.select do |arr|
      arr[0] == 31 &&
      arr[1].even? &&
      arr[2] == 30 &&
      arr[3] == 31 &&
      arr[4].even? &&
      arr[5] == 31
    end

    puts "全件: #{@all_pattern.size}"
    puts "該当: #{@selected_pattern.size}"
    puts "HU個体数: #{@result_1.size}"
    puts "HV個体数: #{@result_2.size}"
    puts "妥協個体: #{@match_pattern.size}"
    puts "妥協確率: #{@match_pattern.size/@selected_pattern.size}"
  end
end

Pokemon.new