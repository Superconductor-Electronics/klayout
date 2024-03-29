# $autorun-early

module LVS

  include DRC

  # The LVS netter object

  # %LVS%
  # @scope
  # @name Netter
  # @brief LVS Reference: Netter object
  # The Netter object provides services related to network extraction
  # from a layout plus comparison against a reference netlist.
  # Similar to the DRC \DRC::Netter (which lacks the compare ability), the
  # relevant method of this object are available as global functions too
  # where they act on a default incarnation. Usually it's not required
  # to instantiate a Netter object explicitly. 
  #
  # The LVS Netter object inherits all methods of the \DRC::Netter.
  #
  # An individual netter object can be created, if the netter results
  # need to be kept for multiple extractions. If you really need
  # a Netter object, use the global \global#netter function:
  #
  # @code
  # # create a new Netter object:
  # nx = netter
  #
  # # build connectivity
  # nx.connect(poly, contact)
  # ...
  #
  # # read the reference netlist
  # nx.schematic("reference.cir")
  #
  # # configure the netlist compare
  # nx.same_circuits("A", "B")
  # ...
  #
  # # runs the compare
  # if ! nx.compare
  #   puts("no equivalence!")
  # end
  # @/code

  class LVSNetter < DRCNetter

    def initialize(engine)
      super
    end

    def _make_data

      if @engine._dss
        @engine._dss.is_singular? || raise("The LVS script features more than one or no layout source - network extraction cannot be performed in such configurations")
        @lvs = RBA::LayoutVsSchematic::new(@engine._dss)
      else
        layout = @engine.source.layout
        cell = @engine.source.cell_obj
        @lvs = RBA::LayoutVsSchematic::new(cell.name, layout.dbu)
      end

      @l2n = @lvs
      @comparer = RBA::NetlistComparer::new

    end

    # %LVS%
    # @name lvs_data
    # @brief Gets the internal RBA::LayoutVsSchematic object
    # @synopsis lvs_data
    # The RBA::LayoutVsSchematic object provides access to the internal details of
    # the netter object.

    def lvs_data
      l2n_data
      @lvs
    end

    def _clear_data
      super
      @lvs = nil
      @schematic = nil
    end

    def _take_data
      data = super
      @lvs = nil
      @schematic = nil
      data
    end

    # %LVS%
    # @name compare
    # @brief Compares the extracted netlist vs. the schematic
    # @synopsis compare
    # Before using this method, a schematic netlist has to be loaded with \schematic.
    # The compare can be configured in more details using \same_nets, \same_circuits,
    # \same_device_classes and \equivalent_pins.
    #
    # This method will return true, if the netlists are equivalent and false
    # otherwise.

    def compare
      lvs_data.reference = _ensure_two_netlists[1]
      lvs_data.compare(@comparer)
    end

    def _ensure_two_netlists

      netlist || raise("No netlist present (not extracted?)")
      schematic || raise("No reference schematic present (not set with 'schematic'?)")

      [ netlist, schematic ]

    end
      
    # %LVS%
    # @name same_nets
    # @brief Establishes an equivalence between the nets
    # @synopsis same_nets(circuit, net_a, net_b)
    # @synopsis same_nets(circuit_a, net_a, circuit_b, net_b)
    # This method will force an equivalence between the net_a and net_b from circuit_a
    # and circuit_b (circuit in the three-argument form is for both circuit_a and circuit_b).
    #
    # In the four-argument form, the circuits can be either given by name or as Circuit
    # objects. In the three-argument form, the circuit has to be given by name. 
    # Nets can be either given by name or as Net objects.
    #
    # After using this function, the compare algorithm will consider these nets equivalent.
    # Use this method to provide hints for the comparer in cases which are difficult to
    # resolve otherwise.
    #
    # Before this method can be used, a schematic netlist needs to be loaded with
    # \schematic.

    def same_nets(*args)

      if args.size < 3 
        raise("Too few arguments to 'same_nets' (need at least 3)")
      end
      if args.size > 4 
        raise("Too many arguments to 'same_nets' (need max 4)")
      end

      if args.size == 3
        ( ca, a, b ) = args
        cb = ca
        ca.is_a?(String) || raise("Circuit argument of 'same_nets' must be a string")
      else
        ( ca, a, cb, b ) = args
        [ ca, cb ].each do |n|
          n.is_a?(String) || n.is_a?(RBA::Net) || raise("Circuit arguments of 'same_nets' must be strings or Net objects")
        end
      end

      [ a, b ].each do |n|
        n.is_a?(String) || n.is_a?(RBA::Net) || raise("Net arguments of 'same_nets' must be strings or Net objects")
      end

      ( nl_a, nl_b ) = _ensure_two_netlists

      if ca.is_a?(String)
        circuit_a = nl_a.circuit_by_name(ca) || raise("Not a valid circuit name in extracted netlist: #{ca}")
      else 
        circuit_a = ca
      end

      if cb.is_a?(String)
        circuit_b = nl_b.circuit_by_name(cb) || raise("Not a valid circuit name in reference netlist: #{cb}")
      else
        circuit_b = cb
      end

      if a.is_a?(String)
        net_a = circuit_a.net_by_name(a) || raise("Not a valid net name in extracted netlist: #{a} (for circuit #{circuit_a})")
      else
        net_a = a
      end

      if b.is_a?(String)
        net_b = circuit_b.net_by_name(b) || raise("Not a valid net name in reference netlist: #{b} (for circuit #{circuit_b})")
      else
        net_b = b
      end

      @comparer.same_nets(net_a, net_b)
      
    end

    # %LVS%
    # @name same_circuits
    # @brief Establishes an equivalence between the circuits
    # @synopsis same_circuits(circuit_a, circuit_b)
    # This method will force an equivalence between the two circuits.
    # By default, circuits are identified by name. If names are different, this
    # method allows establishing an explicit correspondence.
    # 
    # One of the circuits may be nil. In this case, the corresponding
    # other circuit is mapped to "nothing", i.e. ignored.
    #
    # Before this method can be used, a schematic netlist needs to be loaded with
    # \schematic.

    def same_circuits(a, b)

      a.is_a?(String) || a == nil || b.is_a?(String) || b == nil || raise("Both arguments of 'same_circuits' need to be strings or nil")

      ( nl_a, nl_b ) = _ensure_two_netlists

      circuit_a = a && (nl_a.circuit_by_name(a) || raise("Not a valid circuit name in extracted netlist: #{a}"))
      circuit_b = b && (nl_b.circuit_by_name(b) || raise("Not a valid circuit name in reference netlist: #{b}"))

      @comparer.same_circuits(circuit_a, circuit_b)
      
    end

    # %LVS%
    # @name same_device_classes
    # @brief Establishes an equivalence between the device classes
    # @synopsis same_device_classes(class_a, class_b)
    # This method will force an equivalence between the two device classes.
    # Device classes are also known as "models".
    # By default, device classes are identified by name. If names are different, this
    # method allows establishing an explicit correspondence.
    #
    # One of the device classes may be nil. In this case, the corresponding
    # other device class is mapped to "nothing", i.e. ignored.
    #
    # Before this method can be used, a schematic netlist needs to be loaded with
    # \schematic.

    def same_device_classes(a, b)

      a.is_a?(String) || a == nil || b.is_a?(String) || b == nil || raise("Both arguments of 'same_device_classes' need to be strings or nil")

      ( nl_a, nl_b ) = _ensure_two_netlists

      dc_a = a && (nl_a.device_class_by_name(a) || raise("Not a valid device class in extracted netlist: #{a}"))
      dc_b = b && (nl_b.device_class_by_name(b) || raise("Not a valid device class in reference netlist: #{b}"))

      @comparer.same_device_classes(dc_a, dc_b)
      
    end

    # %LVS%
    # @name equivalent_pins
    # @brief Marks pins as equivalent
    # @synopsis equivalent_pins(circuit, pin ...)
    # This method will mark the given pins as equivalent. This gives the compare algorithm
    # more degrees of freedom when establishing net correspondence. Typically this method
    # is used to declare inputs from gates are equivalent where are are logically, but not
    # physically (e.g. in a CMOS NAND gate):
    #
    # @code
    # netter.equivalent_pins("NAND2", 0, 1)
    # @/code
    #
    # The circuit argument is either a circuit name (a string) or a Circuit object
    # from the schematic netlist.
    #
    # The pin arguments are zero-based pin numbers, where 0 is the first number, 1 the second etc.
    # If the netlist provides named pins, names can be used instead of numbers.
    #
    # Before this method can be used, a schematic netlist needs to be loaded with
    # \schematic.

    def equivalent_pins(circuit, *pins)

      circuit.is_a?(String) || 
        raise("Circuit argument of 'equivalent_pins' needs to be a string")

      pins.each do |a|
        a.is_a?(String) || 
          a.respond_to?(:to_i) ||
          raise("All pin arguments of 'equivalent_pins' need to be strings or numbers")
      end

      ( nl_a, nl_b ) = _ensure_two_netlists

      circuit_b = nl_b.circuit_by_name(circuit) || raise("Not a valid circuit name in reference netlist: #{circuit}")

      pins_by_index = []
      circuit_b.each_pin { |p| pins_by_index << p }

      pin_ids_b = pins.collect do |p|
        if p.is_a?(String)
          pin = circuit_b.pin_by_name(p) || raise("Not a valid pin name in circuit '#{circuit}': #{p}")
        else
          pin = pins_by_index[p.to_i] || raise("Not a valid pin index in circuit '#{circuit}': #{p}")
        end  
        pin.id
      end

      @comparer.equivalent_pins(circuit_b, pin_ids_b)
      
    end

    # %LVS%
    # @name schematic
    # @brief Gets, sets or reads the reference netlist
    # @synopsis schematic(filename)
    # @synopsis schematic(filename, reader)
    # @synopsis schematic(netlist)
    # @synopsis schematic
    # If no argument is given, the current schematic netlist is returned. nil is 
    # returned if no schematic netlist is set yet.
    #
    # If a filename is given (first two forms), the netlist is read from the given file.
    # If no reader is provided, Spice format will be assumed. The reader object is a
    # RBA::NetlistReader object and allows detailed customization of the reader process.
    #
    # Alternatively, a RBA::Netlist object can be given which is obtained from any other
    # source.
      
    def schematic(schematic = nil, reader = nil)

      if !schematic

        # without arguments: return current schematic
        @schematic

      elsif schematic.is_a?(RBA::Netlist)

        @schematic = netlist

      else

        schematic.is_a?(String) || raise("First argument must be string or netlist in 'schematic'")

        if reader
          reader.is_a?(RBA::NetlistReader) || raise("Second argument must be netlist reader object in 'schematic'")
        else
          reader = RBA::NetlistSpiceReader::new
        end

        netlist_file = @engine._make_path(schematic)
        @engine.info("Reading netlist: #{netlist_file} ..")

        netlist = RBA::Netlist::new
        netlist.read(netlist_file, reader)

        @schematic = netlist 

      end

    end

    # %LVS%
    # @name min_caps
    # @brief Ignores capacitors with a capacitance below a certain value
    # @synopsis min_caps(threshold)
    # After using this method, the netlist compare will ignore capacitance devices
    # with a capacitance values below the given threshold (in Farad).

    def min_caps(value)
      lvs_data
      @comparer.min_capacitance = value.to_f
    end
      
    # %LVS%
    # @name max_res
    # @brief Ignores resistors with a resistance above a certain value
    # @synopsis max_res(threshold)
    # After using this method, the netlist compare will ignore resistor devices
    # with a resistance value above the given threshold (in Farad).

    def max_res(value)
      lvs_data
      @comparer.max_resistance = value.to_f
    end

    def max_depth(value)
      lvs_data
      @comparer.max_depth = value.to_i
    end

    def max_branch_complexity(value)
      lvs_data
      @comparer.max_branch_complexity = value.to_i
    end

  end
  
end

