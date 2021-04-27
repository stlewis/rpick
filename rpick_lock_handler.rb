module Rpick
  # This class encapsulates everything to do with lock handling. Measuring, choosing the right pick/tool, picking, popping, relocking, etc.
  class LockHandler
    attr_accessor :lock_data

    def initialize(box, picker, box_info = nil)
      @box = box
      @box_id = box.id
      @box_info = box_info
      @picker = picker
      @lock_data = {
        current_caliper_read: nil,
        current_lock_read: nil
      }
      @box_was_relocked = false
      @current_lockpick = nil
    end

    def handle_lock
      @picker.clear_hands([@box_id])
      @picker.cast_maintenance_spells_if_needed('locks')

      if @picker.settings[:lock_handling][:always_wedge_locked] && @picker.can_wedge_boxes? && @picker.has_wedges? && @box.name !~ /plinite/
        result = Rpick::TrapHandler.new(@box, @picker).wedge_box
        return result
      end

      measure_lock
      waitrt?
      pick_result = pick_box

      if pick_result
        if @picker.can_relock_boxes? && !@box_was_relocked && @picker.session_settings[:relock_boxes] && @box.name !~ /plinite/
          relocked = relock_box
          if relocked && @picker.session_settings[:workflow] == 'worker'
            @box_was_relocked = true
            handle_lock
          end

        end
        fput "stop 403" if @picker.settings[:lock_handling][:cancel_403] && Spell[403].active?
        return pick_result
      end

      unpickable_action = @picker.settings[:lock_handling][:unpickable_box_action]
      if unpickable_action != 'Return' && @box.name !~ /plinite/
        # Try casting unlock
        if unpickable_action == 'Unlock (407)' && @picker.knows_407?
          return handle_lock_with_407
        end

        # Try wedging if able
        if (unpickable_action == 'Unlock (407)' && ((!@picker.knows_407? && @picker.can_wedge_boxes?) || unpickable_action == 'Wedge') && @picker.has_wedges?)
          if Rpick::TrapHandler.new(@box, @picker).wedge_box
            fput "stop 403" if @picker.settings[:lock_handling][:cancel_403] && Spell[403].active?
            return true
          end
        end
      end

      fput "stop 403" if @picker.settings[:lock_handling][:cancel_403] && Spell[403].active?
      return false
    end

    def relock_box
      @relocking = true
      result = pick_box
      @relocking = false
      return result
    end

    def measure_plinite
      result = dothistimeout "detect ##{@box_id}", 3, Dictionary.plinite_detection_regex

      if result =~ Dictionary.successful_plinite_detection_regex
        @lock_data[:current_caliper_read] = $1
        return @lock_data
      end

      if result =~ Dictionary.plinite_core_removed_regex
        @box_is_open = true
        return true
      end
    end

    def measure_lock
      @picker.clear_hands([@box_id])
      return measure_plinite if @box.noun =~ /plinite/

      return true if @box_is_open

      return false unless @picker.can_use_calipers? && @picker.has_calipers? && @picker.settings[:lock_handling][:use_calipers]
      return false if @picker.session_settings[:always_use_vaalin] || @picker.session_settings[:start_with_copper]

      fput "get ##{@picker.inventory[:calipers][:id]}"
      measure_result = dothis "lm measure ##{@box_id}", Dictionary.caliper_read_regex
      waitrt?

      if measure_result =~ Dictionary.unsuccessful_caliper_read_regex
        measure_lock
      end

      if measure_result =~ Dictionary.successful_caliper_read_regex
        @lock_data[:current_caliper_read] = $2.to_i
        caliper_stow =  "put ##{@picker.inventory[:calipers][:id]} in ##{@picker.inventory[:containers][:locksmith_container][:id]}"
        dothistimeout caliper_stow, 1, /You put.*#{@picker.inventory[:calipers][:name]}.*"/
      end
    end

    def lock_difficulty
      @lock_data[:current_lock_read] ? @lock_data[:current_lock_read] : @lock_data[:current_caliper_read]
    end

    def fetch_lockpick(lockpick_type)
      best_lockpick = @picker.inventory_manager.get_lockpick_of_type(lockpick_type)

      if !best_lockpick
        echo "None of your #{lockpick_type.to_s} lockpicks are accessible, or this lock is out of your range!"
        @current_lockpick = nil
        return false
      end

      previous_lockpick = @current_lockpick
      @current_lockpick = best_lockpick

      @picker.cast_403_if_needed(best_lockpick[:type], lock_difficulty)

      return true if @current_lockpick == previous_lockpick

      @picker.clear_hands([@box_id])
      fput "get ##{best_lockpick[:id]}"

      return true
    end

    def get_best_lockpick_for_unmeasured
      type = :copper if @picker.session_settings[:start_with_copper]
      type ||= :vaalin
      fetch_lockpick(type)
    end

    def get_best_lockpick
      return get_lockpick_by_critter_level if @box_info && @picker.settings[:locksmith_pool][:lockpick_by_critter_level]
      return fetch_lockpick(:vaalin) if @picker.should_use_vaalin?
      # We don't have a lock difficulty and we don't have a point to scale up from
      return get_best_lockpick_for_unmeasured if !lock_difficulty && !@better_than

      if lock_difficulty.to_i > @picker.max_lock_attempt
        echo "This box/plinite is too difficult based on your settings: "
        echo " This box/plinite: -#{lock_difficulty} Your max: #{@picker.max_lock_attempt}"
        @current_lockpick = nil
        return false
      end

      best_type = nil
      mindex = @better_than ? (Dictionary.lockpick_modifiers.keys.index(@better_than)) + 1 : 0

      Dictionary.lockpick_modifiers.keys[mindex..-1].each do |lockpick_type|
        break if best_type

        if @picker.can_pick_box?(lockpick_type, lock_difficulty) || (@picker.can_pick_box?(lockpick_type, lock_difficulty, with_lore: true) && @picker.knows_403?)
          best_type = lockpick_type
        end
      end

      return fetch_lockpick(best_type)
    end

    def get_lockpick_by_critter_level

      critter_level = @box_info[:critter_level].to_i
      mindex = @better_than ? (Dictionary.lockpick_modifiers.keys.index(@better_than)) + 1 : 0
      best_type = nil

      Dictionary.lockpick_modifiers.keys[mindex..-1].each do |lockpick_type|
        break unless best_type.empty?
        min = settings[:locksmith_pool][:lockpicks_by_critter_level][lockpick_type][:min]
        min = 0 if mindex > 0 # If we know we've skipped past picks that meet the bottom end criteria, just care about top end.

        max = settings[:locksmith_pool][:lockpicks_by_critter_level][lockpick_type][:max]
        best_type = lockpick_type if critter_level.between?(min, max)
      end

      best_type ||= :vaalin
      fetch_lockpick(best_type)
    end

    def pick_box
      return true if @box_is_open
      return false unless get_best_lockpick

      pick_result = nil
      attempt_roll = nil

      fput @relocking ? "lm relock ##{@box_id}" : @picker.pick_command(@box)
      waitrt?

      while line = get
        attempt_roll = $1.to_i if line =~ Dictionary.pick_attempt_regex

        if line =~ Dictionary.pick_result_regex
          pick_result = line
          break
        end
      end

      if pick_result =~ Regexp.union(Dictionary.lock_already_open_regex, Dictionary.lock_success_regex, Dictionary.plinite_success_regex)

        if pick_result =~ Dictionary.lock_success_regex
          actual_lock_strength = $1.to_i
          caliper_lock_read = @lock_data[:current_caliper_read].to_i > 0 ? @lock_data[:current_caliper_read] : nil
          @picker.wild_measure_miss = (caliper_lock_read - actual_lock_strength ).abs >= Dictionary.wild_measure_miss_threshold
        end

        @picker.box_count += 1
        return true
      end

      return false if pick_result =~ Dictionary.plinite_unextractable_regex

      pick_again = false
      pick_again = true if pick_result =~ Dictionary.no_lock_read_regex

      if pick_result =~ Dictionary.pick_bent_regex
        @picker.repair_lockpick(@current_lockpick[:id]) if @picker.can_repair_lockpicks?
        waitrt?
        pick_again = true
      end

      if pick_result =~ Dictionary.pick_broken_regex
        @picker.inventory_manager.handle_broken_pick(@current_lockpick[:id])
        waitrt?
        pick_again = true
      end

      if pick_result =~ Dictionary.lock_read_regex
        @lock_data[:current_lock_read] = $1.to_i
        echo "Got a read on the box, switching to best-suited lockpick"
        pick_again = true
      end

      return false if !pick_again

      if attempt_roll && @picker.settings[:lock_handling][:lockpick_switch_roll] <= attempt_roll || @current_lockpick[:broken]
        # Go up a pick size then try again
        if @current_lockpick[:type] == :vaalin
          if @picker.settings[:lock_handling][:vaalin_switch_roll] <= attempt_roll
            echo "Not able to pick this lock and above the vaalin switch threshold"
            return false
          end
        else
          echo "Going up to next lockpick size"
          @better_than = @current_lockpick[:type]
        end

        pick_box
      else
        pick_box
      end
    end

    def handle_lock_with_407
      return false if @box.name =~ /mithril|enruned/

      @picker.cast_407_if_needed(@box_id, true)
      while line = get
        if line =~ Dictionary.box_pop_success_regex
          return true
        end

        if line =~ Dictionary.box_pop_failure_regex
          handle_lock_with_407
        end
      end
    end
  end
end
