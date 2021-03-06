module Rpick
  # This class encapsulates everything to do with trap handling. From detection to proper disarmament
  # to the use of spells and tools required to successfully disarm. Includes "failsafe" methods to
  # shortcircuit out of range traps, etc.
  class TrapHandler
    attr_reader :box_id, :trap_data, :box_is_open

    def initialize(box, picker)
      @box = box
      @box_id = box.id
      @picker = picker
      @trap_data = nil
      @has_trap = false
      @failed_last_attempt = false
    end

    def box_is_open?
      @box_is_open
    end

    def wedge_in_hand
      wedge_in_right = GameObj.right_hand.noun == 'wedge' ? GameObj.right_hand.id : nil
      wedge_in_left  = GameObj.left_hand.noun == 'wedge' ? GameObj.left_hand.id : nil
      wedge_in_right ? wedge_in_right : wedge_in_left
    end

    def detect_and_disarm
      @picker.clear_hands([@box_id])
      @picker.cast_maintenance_spells_if_needed('traps')

      detect_times_setting = @picker.settings[:trap_handling][:detect_count].to_i

      times_to_detect = detect_times_setting > 0 ? detect_times_setting : 1

      times_to_detect.times do
        detect_trap
        waitrt?
        break if @has_trap
      end

      return true unless @has_trap

      if @trap_data[:difficulty] > @picker.max_trap_attempt
        echo "This box is too difficult based on your settings: "
        echo " This box: -#{@trap_data[:difficulty]} Your max: #{@picker.max_trap_attempt}"
        return false
      end

      disarm_trap
      return @trap_data[:is_disarmed]
    end

    def detect_trap
      fput "detect ##{box_id}"
      waitrt?
      while line = get
        if line =~ Dictionary.trap_detection_regexes[:already_open]
          @box_is_open = true # The LockHandler won't attempt to repick this box after successful disarm based on this setting.
          return false
        end

        clean_box_match = Regexp.union(Dictionary.trap_detection_regexes[:clean],
                                       Dictionary.trap_detection_regexes[:magically_disarmed],
                                       Dictionary.trap_detection_regexes[:manually_disarmed])
        return false if line =~ clean_box_match


        Dictionary.trap_detection_regexes.each do |trap_type, regex|
          if line =~ regex
            @has_trap = true
            @trap_data = {
              type: trap_type,
              is_disarmed: false
            }
          end
        end

        if line =~ Dictionary.trap_read_regex
          @trap_data[:difficulty] = $3.to_i
          break
        end
      end

      return @has_trap
    end

    def disarm_trap

      if @picker.settings[:trap_handling][:always_408] && @picker.knows_408?
        return handle_trap_with_408
      end

      unless @picker.can_disarm_trap?(@trap_data[:difficulty], with_lore: @picker.knows_404?)
        echo "Can't get this trap! Difficulty: #{@trap_data[:difficulty]}. Your best: #{@picker.max_trap(with_lore: @picker.knows_404?) }"
        return false
      end

      @trap_data[:is_disarmed] = standard_disarm unless %i[scarab sphere scales plate].include?(@trap_data[:type])
      if @trap_data[:type] == :scarab
        @picker.say_scarab_found
        scarab_disarm
      end
      scales_disarm if @trap_data[:type] == :scales
      plate_disarm if @trap_data[:type] == :plate
      sphere_disarm if @trap_data[:type] == :sphere

      fput "stop 404" if @picker.settings[:trap_handling][:cancel_404] && Spell[404].active?
      return @trap_data[:is_disarmed]
    end

    def wedge_box
      return false unless @picker.has_wedges? && @picker.can_wedge_boxes?

      @picker.cast_404_if_needed(@trap_data[:difficulty], @failed_last_attempt)
      waitrt?

      @picker.clear_hands([@box_id, wedge_in_hand])

      fput "get my wedge" unless wedge_in_hand

      fput "lm wedge ##{@box_id}"

      while line = get
        if line =~ Dictionary.wedge_result_regex
          if line =~ /Roundtime/
            waitrt?
            return wedge_box
          end

          if line =~ /splits away from the casing/
            waitrt?
            fput "put my wedge in ##{@picker.inventory[:containers][:wedge_container][:id]}"
            @box_is_open = true
            @trap_data[:is_disarmed] = true
            return true
          end
        end
      end
    end

    private

    def standard_disarm
      @picker.inventory_manager.check_toolkit
      if %i[needle spores boomer].include?(@trap_data[:type]) && @picker.inventory[:putty_count] == 0
        if @picker.settings[:containers_and_equipment][:auto_refill_toolkit]
          Rpick::AncillaryActions.new(@picker).refill_toolkit
        else
          echo "No putty to disarm this trap. Aborting"
          return false # TODO Consider whether or not situations like this should kill the script.
        end
      end

      if @trap_data[:trap_type] == :acid_vial && @picker.inventory[:cottonball_count] == 0
        if @picker.settings[:containers_and_equipment][:auto_refill_toolkit]
          Rpick::AncillaryActions.new(@picker).refill_toolkit
        else
          echo "No cottonballs to disarm this trap. Aborting"
          return false # TODO Consider whether or not situations like this should kill the script.
        end
      end

      @picker.cast_404_if_needed(@trap_data[:difficulty], @failed_last_attempt)
      waitrt?

      success_match = Dictionary.disarm_success_regex
      failure_match = Dictionary.disarm_failure_regex
      tripped_match = Dictionary.tripped_trap_regex
      detector      = Regexp.union(success_match, failure_match, tripped_match)

      disarm_result = dothis "disarm ##{@box_id}", detector
      waitrt?

      if disarm_result =~ success_match
        @trap_data[:is_disarmed] = true
        @failed_last_attempt = false
        return true
      end

      if disarm_result =~ tripped_match
        echo "Trap tripped! Aborting!"
        exit
      end

      @failed_last_attempt = true
      standard_disarm
    end

    def scarab_disarm
      @picker.cast_404_if_needed(@trap_data[:difficulty], @failed_last_attempt)

      success_match = Dictionary.scarab_down_regex
      failure_match = Dictionary.disarm_failure_regex
      tripped_match = Dictionary.scarab_tripped_regex

      current_scarabs = GameObj.loot.map{|l| l.id if l.noun == 'scarab' }

      detector      = Regexp.union(success_match, failure_match, tripped_match)
      disarm_result = dothis "disarm ##{@box_id}", detector

      if disarm_result =~ failure_match
        @failed_last_attempt = true
        waitrt?
        scarab_disarm
      end

      if disarm_result =~ tripped_match
        echo "Scarab Loose! Aborting!"
        exit
      end

      if disarm_result =~ success_match
        @picker.say_scarab_on_ground
        waitrt?
        @failed_last_attempt = false
        this_scarab = GameObj.loot.select{|l| l.noun == 'scarab' && !current_scarabs.include?(l.id) }.first
        # TODO Think about ways to improve this, especially bailing out if the grab trips the bug
        setting_scarab_disarm_count = @picker.settings[:trap_handling][:scarab_disarm_count]
        scarab_disarm_count = setting_scarab_disarm_count.to_i > 0 ? setting_scarab_disarm_count : 1
        scarab_disarm_count.times do
          fput "disarm ##{this_scarab.id}"
          waitrt?
        end

        waitrt?
        fput "get ##{this_scarab.id}"
        fput "put scarab in ##{@picker.inventory[:containers][:scarab_container][:id]}"
        @picker.say_scarab_safe
        @trap_data[:is_disarmed] = true
        return true
      end
    end

    def scales_disarm
      if !@picker.has_dagger?
        echo "No dagger to disarm this trap with"
        return false # TODO Consider whether or not this should abort the script
      end

      if LockHandler.new(@box, @picker).handle_lock
        @box_is_open = true # The LockHandler won't attempt to repick this box after successful disarm based on this setting.

        @picker.clear_hands([@box_id])

        fput "get #{@picker.inventory[:dagger][:id]}"
        if standard_disarm
          fput "put ##{@picker.inventory[:dagger][:id]} in ##{@picker.inventory[:containers][:scale_trap_weapon_container][:id]}"
        end
      end
    end

    def plate_disarm
      return standard_disarm if @picker.has_vials?
      return true if wedge_box
      echo "Can't disarm this box, no vials and wedging is impossible"
      return false
    end

    def sphere_disarm
      # Any old lockpick'll do
      fput "get my lock from ##{@picker.inventory[:containers][:lockpick_container][:id]}"
      if standard_disarm
        fput "put my lock in ##{@picker.inventory[:containers][:lockpick_container][:id]}"
        return true
      end
    end

    def handle_trap_with_408
      @picker.cast_408_if_needed(@box_id, @trap_data, true)
      while line = get
        if line =~ Dictionary.box_pop_disarm_success_regex
          @trap_data[:is_disarmed] = true
          return true
        end

        if line =~ Dictionary.box_pop_disarm_failure_regex
          handle_trap_with_408 # TODO This will theoretically loop forever on an unreachable box?
        end
      end
    end

  end
end
