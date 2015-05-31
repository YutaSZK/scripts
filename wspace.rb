require 'pry'
class Wspace
  def initialize
    begin
      @code = File.read(ARGV[0])
      @tokens = Array.new
      @pc = 0
      @stack = Array.new
      @heap = Hash.new

      tokenize
      evaluate
    rescue
      raise Exception
    end
  end

  def tokenize
    imp_hash = {
      " " => :stack,
      "\t " => :arith,
      "\t\t" => :heap,
      "\n" => :flow,
      "\t\n" => :io
    }
    imp_regexp = /\A( |\n|\t[ \n\t])/
    # imp_hash = {
    #   "s" => :stack,
    #   "ts" => :arith,
    #   "tt" => :heap,
    #   "n" => :flow,
    #   "tn" => :io
    # }
    # imp_regexp = /\A(s|n|t[snt])/

    while @code.length > 0
      raise Exception unless @code.sub!(imp_regexp, '')
      imp_symbol = imp_hash[$1]
      # imp毎に以降の文章を解釈し、imp, cmd, paramを[Array]tokenに格納
      token = self.send("imp_#{imp_symbol}")
      puts token
      @tokens << token
    end
  end

  # *** tokenize methods ***
  def imp_stack
    stack_hash = {
      " " => :push,
      "\n " => :duplicate,
      "\t " => :copy,
      "\n\t" => :swap,
      "\n\n" => :discard,
      "\t\n" => :slide
    }
    cmd_regexp = /\A( |\n[ \n\t]|\t[ \n])/

    # stack_hash = {
    #   "s" => :push,
    #   "ns" => :duplicate,
    #   "ts" => :copy,
    #   "nt" => :swap,
    #   "nn" => :discard,
    #   "tn" => :slide
    # }
    # cmd_regexp = /\A(s|n[snt]|t[sn])/
    raise Exception unless @code.sub!(cmd_regexp, '')
    cmd = stack_hash[$1]
    case cmd
    when :push, :copy, :slide
      param = binary_eval
      return [:stack, cmd, param]
    else
      return [:stack, cmd]
    end
  end

  def imp_arith
    arith_hash = {
      "  " => :add,
      " \t" => :subtract,
      " \n" => :multiple,
      "\t " => :div,
      "\t\t" => :mod
    }
    cmd_regexp = /\A( [ \t\n]|\t[ \t])/

    # arith_hash = {
    #   "ss" => :add,
    #   "st" => :subtract,
    #   "sn" => :multiple,
    #   "ts" => :div,
    #   "tt" => :mod
    # }
    # cmd_regexp = /\A(s[stn]|t[st])/

    raise Exception unless @code.sub!(cmd_regexp, '')
    cmd = arith_hash[$1]
    return [:arith, cmd]
  end

  def imp_heap
    heap_hash = {
      " " => :store,
      "\t" => :retrieve
    }
    cmd_regexp = /\A( |\t)/

    # heap_hash = {
    #   "s" => :store,
    #   "t" => :retrieve
    # }
    # cmd_regexp = /\A(s|t)/

    raise Exception unless @code.sub!(cmd_regexp, '')
    cmd = heap_hash[$1]
    return [:heap, cmd]
  end

  def imp_flow
    flow_hash = {
      "  " => :mark,
      " \t" => :call_subroutine,
      " \n" => :jump_whenever,
      "\t " => :jump_if_zero,
      "\t\t" => :jump_if_negative,
      "\t\n" => :end_subroutine,
      "\n\n" => :end_program
    }
    cmd_regexp = /\A( [ \t\n]|\t[ \t\n]|\n\n)/
    label_regexp = /\A([ \t]*)\n/

    # flow_hash = {
    #   "ss" => :mark,
    #   "st" => :call_subroutine,
    #   "sn" => :jump_whenever,
    #   "ts" => :jump_if_zero,
    #   "tt" => :jump_if_negative,
    #   "tn" => :end_subroutine,
    #   "nn" => :end_program
    # }
    # cmd_regexp = /\A(s[stn]|t[stn]|nn)/
    # label_regexp = /\A([st]*)n/


    raise Exception unless @code.sub!(cmd_regexp, '')
    cmd = flow_hash[$1]

    case cmd
    when :mark, :call_subroutine, :jump_whenever, :jump_if_zero, :jump_if_negative
      raise Exception unless @code.sub!(label_regexp, '')
      param = $1
      label = param.gsub(" ", '0').gsub("\t", '1').to_i(2).to_chr
      # label = param.gsub("s", '0').gsub("t", '1').to_i(2).to_chr
      return [:flow, cmd, label]
    else
      return [:flow, cmd]
    end
  end

  def imp_io
    io_hash = {
      "  " => :output_char,
      " \t" => :output_int,
      "\t " => :read_char,
      "\t\t" => :read_int
    }
    cmd_regexp = /\A( [ \t]|\t[ \t])/

    # io_hash = {
    #   "ss" => :output_char,
    #   "st" => :output_int,
    #   "ts" => :read_char,
    #   "tt" => :read_int
    # }
    # cmd_regexp = /\A(s[st]|t[st])/

    raise Exception unless @code.sub!(cmd_regexp, '')
    cmd = io_hash[$1]
    return [:io, cmd]
  end

  # @return [fixnum] number
  def binary_eval
    # バイナリ部分を取得し数値パラメータとして返す
    num_regexp = /\A([ \t]*)\n/
    # num_regexp = /\A([st]*)n/

    raise Exception unless @code.sub!(num_regexp, '')
    param = $1 # binary

    number = param[1..-1].gsub(" ", '0').gsub("\t", '1').to_i(2)
    # number = param[1..-1].gsub("s", '0').gsub("t", '1').to_i(2)
    return number
  end
  # *** tokenize methods ***


  def label_init
    # _label_markに該当するコードのみ検索し、ラベルを定義
    while true
      _label_mark(@tokens[@pc][2]) if @tokens[@pc][1] == :mark
      @pc += 1
      exit if @tokens.size == @pc
    end
  end

  # @params [Array] @tokens [imp, cmd, (param)?]
  def evaluate
    # ラベルを予め処理し、カウンタを0に戻す
    label_init
    @pc = 0

    while true
      imp, cmd, param = @tokens[@pc]
      # paramの有無で処理を分ける
      if param.nil?
        self.send("_#{imp}_#{cmd}")
      else
        self.send("_#{imp}_#{cmd}", "#{param}")
      end

      @pc += 1
      # 終了条件はflow_endに定義されているので不要
    end
    return true
  end


  # *** evaluate methods ***
  private

  # @params [int] number
  def _stack_push (number)
    @stack.push(number)
  end

  # @params [int] number
  def _stack_copy (number)
    @stack.push(@stack[number])
  end

  # @params [int] number
  def _stack_slide (number)
    puts 'Not Implemented'
  end

  def _stack_duplicate
    @stack.push(@stack.last)
  end

  def _stack_swap
    first = @stack.pop
    second = @stack.pop
    @stack.push(first)
    @stack.push(second)
  end

  def _stack_discard
    @stack.pop
  end

  def _arith_add
    first = @stack.pop
    second = @stack.pop
    @stack.push(first + second)
  end

  def _arith_subtract
    first = @stack.pop
    second = @stack.pop
    @stack.push(first - second)
  end

  def _arith_multiple
    first = @stack.pop
    second = @stack.pop
    @stack.push(first * second)
  end

  def _arith_div
    first = @stack.pop
    second = @stack.pop
    @stack.push(first / second)
  end

  def _arith_mod
    first = @stack.pop
    second = @stack.pop
    @stack.push(first % second)
  end

  def _heap_store
    key = @stack.pop
    val = @stack.pop
    @heap[key] = val
  end

  def _heap_retrieve
    key = @stack.pop
    val = @heap[key]
    @stack.push(val)
  end

  # @params [int] label
  def _flow_mark (label)
    # label_initで予めmarkを全て処理
    unless label == :checked
      @heap[label] = @pc
      @tokens[@pc][3] = :checked
    end
  end

  def _flow_call_subroutine (label)
    # メインプログラムのカウンタ値をスタックに詰み、ラベル位置をカウンタ変数に代入しサブルーチンを開始する
    stack.push(@pc)
    @pc = @heap[label]
  end

  def _flow_jump_whenever (label)
    @pc = @heap[label]
  end

  def _flow_jump_if_zero (label)
    @pc = @heap[label] if @stack.pop == 0
  end

  def _flow_jump_if_negative (label)
    @pc = @heap[label] if @stack.pop < 0
  end

  def _flow_end_subroutine
    # サブルーチン終了時にスタックのトップに詰んだサブルーチン開始前のカウンタ値をカウンタ変数に戻し、1つ外のルーチンの処理に戻る
    # そのため、サブルーチンをまたいでスタックを操作することはできず、終了時にはサブルーチンで詰まれたスタックは全て消費されていなければならない
    # @tokensの要素数より大きな値であった場合は明らかに不正な場合として例外処理するが、範囲内の不正値も存在するため、明確な例外処理は実装できていない
    @pc = stack.pop
    raise Exception if @pc > @tokens.size
  end

  def _flow_end
    exit
  end

  def _io_output_char
    num = @stack.pop.to_s
    print num.to_chr
  end

  def io_output_int
    num = @stack.pop
    print num
  end

  def io_read_char
    read = gets.chomp
    ch = read.to_i(2).to_chr
    @stack.push(ch)
  end

  def io_read_int
    read = gets.chomp
    num = read.to_i
    @stack.push(num)
  end
  # *** evaluate methods ***


end


Wspace.new