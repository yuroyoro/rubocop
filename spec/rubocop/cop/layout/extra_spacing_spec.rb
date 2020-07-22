# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Layout::ExtraSpacing, :config do
  shared_examples 'common behavior' do
    it 'registers an offense and corrects alignment with token ' \
      'not preceded by space' do
      # The = and the ( are on the same column, but this is not for alignment,
      # it's just a mistake.
      expect_offense(<<~RUBY)
        website("example.org")
        name   = "Jill"
            ^^ Unnecessary spacing detected.
      RUBY

      expect_correction(<<~RUBY)
        website("example.org")
        name = "Jill"
      RUBY
    end

    it 'accepts aligned values of an implicit hash literal' do
      expect_no_offenses(<<~RUBY)
        register(street1:    '1 Market',
                 street2:    '#200',
                 :city =>    'Some Town',
                 state:      'CA',
                 postal_code:'99999-1111')
      RUBY
    end

    it 'accepts space between key and value in a hash with hash rockets' do
      expect_no_offenses(<<~RUBY)
        ospf_h = {
          'ospfTest'    => {
            'foo'      => {
              area: '0.0.0.0', cost: 10, hello: 30, pass: true },
            'longname' => {
              area: '1.1.1.38', pass: false },
            'vlan101'  => {
              area: '2.2.2.101', cost: 5, hello: 20, pass: true }
          },
          'TestOspfInt' => {
            'x'               => {
              area: '0.0.0.19' },
            'vlan290'         => {
              area: '2.2.2.29', cost: 200, hello: 30, pass: true },
            'port-channel100' => {
              area: '3.2.2.29', cost: 25, hello: 50, pass: false }
          }
        }
      RUBY
    end

    context 'when spaces are present in a single-line hash literal' do
      it 'registers an offense and corrects hashes with symbol keys' do
        expect_offense(<<~RUBY)
          hash = {a:   1,  b:    2}
                    ^^ Unnecessary spacing detected.
                         ^ Unnecessary spacing detected.
                             ^^^ Unnecessary spacing detected.
        RUBY

        expect_correction(<<~RUBY)
          hash = {a: 1, b: 2}
        RUBY
      end

      it 'registers an offense and corrects hashes with hash rockets' do
        expect_offense(<<~RUBY)
          let(:single_line_hash) {
            {"a"   => "1", "b" => "2"}
                ^^ Unnecessary spacing detected.
          }
        RUBY

        expect_correction(<<~RUBY)
          let(:single_line_hash) {
            {"a" => "1", "b" => "2"}
          }
        RUBY
      end
    end

    it 'registers an offense and corrects extra space before a float' do
      expect_offense(<<~RUBY)
        {:a => "a",
         :b => [nil,  2.5]}
                    ^ Unnecessary spacing detected.
      RUBY

      expect_correction(<<~RUBY)
        {:a => "a",
         :b => [nil, 2.5]}
      RUBY
    end

    it 'registers an offense and corrects extra spacing before a unary plus ' \
      'in an argument list' do
      expect_offense(<<~RUBY)
        assert_difference(MyModel.count, +2,
                          3,  +3, # Extra spacing only here.
                            ^ Unnecessary spacing detected.
                          4,+4)
      RUBY

      expect_correction(<<~RUBY)
        assert_difference(MyModel.count, +2,
                          3, +3, # Extra spacing only here.
                          4,+4)
      RUBY
    end

    it 'registers an offense and corrects double extra spacing ' \
      'in variable assignment' do
      expect_offense(<<~RUBY)
        m    = "hello"
         ^^^ Unnecessary spacing detected.
      RUBY

      expect_correction(<<~RUBY)
        m = "hello"
      RUBY
    end

    it 'ignores whitespace at the beginning of the line' do
      expect_no_offenses('  m = "hello"')
    end

    it 'ignores whitespace inside a string' do
      expect_no_offenses('m = "hello   this"')
    end

    it 'ignores trailing whitespace' do
      expect_no_offenses(['      class Benchmarker < Performer     ',
                          '      end'].join("\n"))
    end

    it 'registers an offense and corrects extra spacing in class inheritance' do
      expect_offense(<<~RUBY)
        class A   < String
               ^^ Unnecessary spacing detected.
        end
      RUBY

      expect_correction(<<~RUBY)
        class A < String
        end
      RUBY
    end
  end

  sources = {
    'lining up assignments' => <<~RUBY,
      website = "example.org"
      name    = "Jill"
    RUBY

    'lining up assignments with empty lines and comments in between' =>
    <<~RUBY,
      a   += 1

      # Comment
      aa   = 2
      bb   = 3

      a  ||= 1
    RUBY

    'aligning with the same character' => <<-RUBY.strip_margin('|'),
      |      y, m = (year * 12 + (mon - 1) + n).divmod(12)
      |      m,   = (m + 1)                    .divmod(1)
    RUBY

    'lining up different kinds of assignments' => <<~RUBY,
      type_name ||= value.class.name if value
      type_name   = type_name.to_s   if type_name

      type_name  = value.class.name if     value
      type_name += type_name.to_s   unless type_name

      a  += 1
      aa -= 2
    RUBY

    'aligning comments on non-adjacent lines' => <<~RUBY,
      include_examples 'aligned',   'var = until',  'test'

      include_examples 'unaligned', "var = if",     'test'
    RUBY

    'aligning = on lines where there are trailing comments' =>
    <<~RUBY,
      a_long_var_name = 100 # this is 100
      short_name1     = 2

      clear

      short_name2     = 2
      a_long_var_name = 100 # this is 100

      clear

      short_name3     = 2   # this is 2
      a_long_var_name = 100 # this is 100
    RUBY

    # WARNING: see mention in tests for AllowBeforeTrailingComments
    # before modifying this test case, or its name
    'aligning tokens with empty line between' => <<~RUBY,
      unless nochdir
        Dir.chdir "/"    # Release old working directory.
      end

      File.umask 0000    # Ensure sensible umask.
    RUBY

    'aligning long assignment expressions that include line breaks' =>
    <<~RUBY,
      size_attribute_name    = FactoryGirl.create(:attribute,
                                                  name:   'Size',
                                                  values: %w{small large})
      carrier_attribute_name = FactoryGirl.create(:attribute,
                                                  name:   'Carrier',
                                                  values: %w{verizon})
    RUBY

    'including east asian width chars in comment line' =>
    <<~RUBY
      hash["キー"] = 100 # hash key is east asian width chars
      hash[key]    = 2   # this key is ascii
    RUBY
  }.freeze

  context 'when AllowForAlignment is true' do
    let(:cop_config) do
      { 'AllowForAlignment' => true, 'ForceEqualSignAlignment' => false }
    end

    include_examples 'common behavior'

    context 'with extra spacing for alignment purposes' do
      sources.each do |reason, src|
        context "such as #{reason}" do
          it 'allows it' do
            expect_no_offenses(src)
          end
        end
      end
    end
  end

  context 'when AllowForAlignment is false' do
    let(:cop_config) do
      { 'AllowForAlignment' => false, 'ForceEqualSignAlignment' => false }
    end

    include_examples 'common behavior'

    context 'with extra spacing for alignment purposes' do
      sources.each do |reason, src|
        context "such as #{reason}" do
          it 'registers offense(s)' do
            inspect_source(src)
            expect(cop.offenses.empty?).to be(false)
          end
        end
      end
    end
  end

  context 'when AllowBeforeTrailingComments is' do
    let(:allow_alignment) { false }
    let(:cop_config) do
      { 'AllowForAlignment' => allow_alignment,
        'AllowBeforeTrailingComments' => allow_comments }
    end
    let(:src_with_extra) { '  object.method(argument)  # this is a comment' }

    context 'true' do
      let(:allow_comments) { true }

      it 'allows it' do
        expect_no_offenses(src_with_extra)
      end

      context "doesn't interfere with AllowForAlignment" do
        context 'being true' do
          let(:allow_alignment) { true }

          sources.each do |reason, src|
            context "such as #{reason}" do
              it 'allows it' do
                expect_no_offenses(src)
              end
            end
          end
        end

        context 'being false' do
          sources.each do |reason, src|
            context "such as #{reason}" do
              it 'registers offense(s)' do
                inspect_source(src)
                # In this one specific test case, the extra space in question
                # is to align comments, so it would be allowed by EITHER ONE
                # being true.  Yes, that means technically it interferes a bit,
                # but specifically in the way it was intended to.
                if reason == 'aligning tokens with empty line between'
                  expect(cop.offenses.empty?).to be(true)
                else
                  expect(cop.offenses.empty?).to be(false)
                end
              end
            end
          end
        end
      end
    end

    context 'false' do
      let(:allow_comments) { false }

      it 'regsiters offense' do
        inspect_source(src_with_extra)
        expect(cop.offenses.empty?).to be(false)
      end

      it 'does not trigger on only one space before comment' do
        src_without_extra = src_with_extra.gsub(/\s*#/, ' #')
        expect_no_offenses(src_without_extra)
      end
    end
  end

  context 'when ForceEqualSignAlignment is true' do
    let(:cop_config) do
      { 'AllowForAlignment' => true, 'ForceEqualSignAlignment' => true }
    end

    it 'does not register offenses for multiple complex nested assignments' do
      expect_no_offenses(<<~RUBY)
        def batch
          @areas   = params[:param].map {
                       var_1      = 123_456
                       variable_2 = 456_123 }
          @another = params[:param].map {
                       char_1 = begin
                                  variable_1_1  = 'a'
                                  variable_1_20 = 'b'

                                  variable_1_300  = 'c'
                                  # A Comment
                                  variable_1_4000 = 'd'

                                  variable_1_50000           = 'e'
                                  puts 'a non-assignment statement without a blank line'
                                  some_other_length_variable = 'f'
                                end
                       var_2  = 456_123 }

          render json: @areas
        end
      RUBY
    end

    it 'does not register an offense if assignments are separated by blanks' do
      expect_no_offenses(<<~RUBY)
        a = 1

        bb = 2

        ccc = 3
      RUBY
    end

    it 'does not register an offense if assignments are aligned' do
      expect_no_offenses(<<~RUBY)
        a   = 1
        bb  = 2
        ccc = 3
      RUBY
    end

    it 'aligns the first assignment with the following assignment' do
      expect_no_offenses(<<~RUBY)
        # comment
        a   = 1
        bb  = 2
      RUBY
    end

    it 'does not register alignment errors on outdented lines' do
      expect_no_offenses(<<~RUBY)
        @areas = params[:param].map do |ca_params|
                   ca_params = ActionController::Parameters.new(stuff)
                 end
      RUBY
    end

    it 'registers an offense and corrects consecutive assignments ' \
      'that are not aligned' do
      expect_offense(<<~RUBY)
        a = 1
        bb = 2
           ^ `=` is not aligned with the preceding assignment.
        ccc = 3
            ^ `=` is not aligned with the preceding assignment.

        abcde        = 1
        a                 = 2
                          ^ `=` is not aligned with the preceding assignment.
        abc = 3
            ^ `=` is not aligned with the preceding assignment.
      RUBY

      expect_correction(<<~RUBY)
        a   = 1
        bb  = 2
        ccc = 3

        abcde = 1
        a     = 2
        abc   = 3
      RUBY
    end

    it 'register offenses and correct consecutive operator assignments ' \
      'which are not aligned' do
      expect_offense(<<~RUBY)
        a += 1
        bb = 2
        ccc <<= 3
            ^^^ `=` is not aligned with the preceding assignment.

        abcde        = 1
        a                 *= 2
                          ^^ `=` is not aligned with the preceding assignment.
        abc ||= 3
            ^^^ `=` is not aligned with the preceding assignment.
      RUBY

      expect_correction(<<~RUBY)
        a    += 1
        bb    = 2
        ccc <<= 3

        abcde = 1
        a    *= 2
        abc ||= 3
      RUBY
    end

    it 'registers an offense and corrects consecutive aref assignments ' \
      'which are not aligned' do
      expect_offense(<<~RUBY)
        a[1] = 1
        bb[2,3] = 2
                ^ `=` is not aligned with the preceding assignment.
        ccc[:key] = 3
                  ^ `=` is not aligned with the preceding assignment.

        abcde[0]        = 1
        a                 = 2
                          ^ `=` is not aligned with the preceding assignment.
        abc += 3
            ^^ `=` is not aligned with the preceding assignment.
      RUBY

      expect_correction(<<~RUBY)
        a[1]      = 1
        bb[2,3]   = 2
        ccc[:key] = 3

        abcde[0] = 1
        a        = 2
        abc     += 3
      RUBY
    end

    it 'register offenses and correct consecutive attribute assignments ' \
      'which are not aligned' do
      expect_offense(<<~RUBY)
        a.attr = 1
        bb &&= 2
           ^^^ `=` is not aligned with the preceding assignment.
        ccc.s = 3
              ^ `=` is not aligned with the preceding assignment.

        abcde.blah        = 1
        a.attribute_name              = 2
                                      ^ `=` is not aligned with the preceding assignment.
        abc[1] = 3
               ^ `=` is not aligned with the preceding assignment.
      RUBY

      expect_correction(<<~RUBY)
        a.attr = 1
        bb   &&= 2
        ccc.s  = 3

        abcde.blah       = 1
        a.attribute_name = 2
        abc[1]           = 3
      RUBY
    end

    it 'register offenses and correct complex nested assignments' do
      expect_offense(<<~RUBY)
        def batch
          @areas = params[:param].map {
                       var_1 = 123_456
                       variable_2 = 456_123 }
                                  ^ `=` is not aligned with the preceding assignment.
          @another = params[:param].map {
                   ^ `=` is not aligned with the preceding assignment.
                       char_1 = begin
                                  variable_1_1     = 'a'
                                  variable_1_20  = 'b'
                                                 ^ `=` is not aligned with the preceding assignment.

                                  variable_1_300    = 'c'
                                  # A Comment
                                  variable_1_4000      = 'd'
                                                       ^ `=` is not aligned with the preceding assignment.

                                  variable_1_50000     = 'e'
                                  puts 'a non-assignment statement without a blank line'
                                  some_other_length_variable     = 'f'
                                                                 ^ `=` is not aligned with the preceding assignment.
                                end
                       var_2 = 456_123 }
                             ^ `=` is not aligned with the preceding assignment.

          render json: @areas
        end
      RUBY

      expect_correction(<<~RUBY, loop: false)
        def batch
          @areas   = params[:param].map {
                       var_1      = 123_456
                       variable_2 = 456_123 }
          @another = params[:param].map {
                       char_1 = begin
                                  variable_1_1  = 'a'
                                  variable_1_20 = 'b'

                                  variable_1_300  = 'c'
                                  # A Comment
                                  variable_1_4000 = 'd'

                                  variable_1_50000           = 'e'
                                  puts 'a non-assignment statement without a blank line'
                                  some_other_length_variable = 'f'
                                end
                       var_2  = 456_123 }

          render json: @areas
        end
      RUBY
    end

    it 'does not register an offense when optarg equals is not aligned with ' \
       'assignment equals sign' do
      expect_no_offenses(<<~RUBY)
        def method(arg = 1)
          var = arg
        end
      RUBY
    end
  end
end
