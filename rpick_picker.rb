module Rpick
  # This class encapsulates information about the individual running this script.
  # Things like their lock mastery training, max trap and lock, spell capabilities, etc.
  class Picker
    attr_reader :inventory_manager, :inventory, :lock_mastery_ranks, :settings
    attr_accessor :box_count, :session_settings, :wild_measure_miss

    def initialize(settings, session_settings = {})
      @wild_measure_miss = false
      @settings = settings
      @session_settings = session_settings
      @inventory_manager = InventoryManagement.new(settings)
      @inventory = @inventory_manager.inventory
      @box_count = 0

      parse_guild_info
    end

    def dex_bonus
      if defined?(Stats.enhanced_dex) and Stats.enhanced_dex[0] > 0
          return Stats.enhanced_dex[1]
      else
          return Stats.dex[1]
      end
    end

    def pick_locks_skill
      Skills.to_bonus(Skills.pickinglocks)
    end

    def disarm_traps_skill
      Skills.to_bonus(Skills.disarmingtraps)
    end

    def lock_lore_bonus
      lore_bonus(403, pick_locks_skill, knows_403?)
    end

    def trap_lore_bonus
      lore_bonus(404, pick_locks_skill, knows_404?)
    end

    def max_trap(with_lore: false)
      base_trap = (dex_bonus + disarm_traps_skill) - 1
      with_lore ? base_trap + trap_lore_bonus : base_trap
    end

    def max_trap_attempt
      max_trap_setting = @settings[:trap_handling][:max_trap]
      if max_trap_setting < 0
        return max_trap(with_lore: true) + max_trap_setting
      elsif max_trap_setting == 0
        return Dictionary.theoretical_max_trap
      else
        return max_trap_setting
      end
    end

    def max_lock(lockpick_type, with_lore: false)
      lockpick_modifier = Dictionary.lockpick_modifiers[lockpick_type]
      unlored_lock = dex_bonus + pick_locks_skill
      lored_lock = unlored_lock + lock_lore_bonus

      base_lock = with_lore ? lored_lock : unlored_lock

      (base_lock * lockpick_modifier).floor - 1
    end

    def max_lock_attempt
      max_lock_setting = @settings[:lock_handling][:max_lock]

      if max_lock_setting < 0
        return max_lock(:vaalin, with_lore: true) + max_lock_setting
      elsif max_lock_setting == 0
        return Dictionary.theoretical_max_lock
      else
        return max_lock_setting
      end
    end

    def can_pick_box?(lockpick_type, lock_difficulty, with_lore: false)
      best_with_pick = max_lock(lockpick_type, with_lore: with_lore)

      (lock_difficulty < best_with_pick) && (lock_difficulty < max_lock_attempt)
    end

    def can_safely_pick_box?(lockpick_type, lock_difficulty, with_lore: false)
      safe_threshold = max_lock(lockpick_type, with_lore: with_lore) - 60
      safe_threshold >= lock_difficulty
    end

    def can_disarm_trap?(trap_difficulty, with_lore: false)
      mt = max_trap(with_lore: with_lore)
      (trap_difficulty < mt) && (trap_difficulty < max_trap_attempt)
    end

    def can_safely_disarm_trap?(trap_difficulty, with_lore: false)
      safe_threshold = max_trap(with_lore: with_lore) - 60

      trap_difficulty < safe_threshold
    end

    def needs_disarm_lore?(trap_difficulty, failed_attempt = false)
      return false if @settings[:trap_handling][:use_404] == 'Never'
      return true if @settings[:trap_handling][:use_404] == 'Always'
      return true if trap_difficulty > threshold_for_404 && @settings[:trap_handling][:use_404] == 'At Threshold'

      return true if failed_attempt # If we fail a disarm, always cast lores

      # If you can't get this trap without lore, but casting lores puts it
      # within your reach minus the user-set threshold, cast lores.
      if !can_disarm_trap?(trap_difficulty) && can_disarm_trap?(trap_difficulty, with_lore: true)
        return true
      end
    end

    def threshold_for_404
      threshold_number = @settings[:trap_handling][:threshold_404]

      if threshold_number < 0
        max_trap + threshold_number
      else
        return threshold_number
      end
    end

    def needs_picking_lore?(lockpick_type, lock_difficulty)
      return false if @settings[:lock_handling][:use_403] == 'Never'
      return true if @settings[:lock_handling][:use_403] == 'Always'
      return true if lock_difficulty > threshold_for_403(lockpick_type) && @settings[:lock_handling][:use_403] == 'At Threshold'

      return !can_pick_box?(lockpick_type, lock_difficulty) && can_pick_box?(lockpick_type, lock_difficulty, with_lore: true)
    end

    def threshold_for_403(lockpick_type)
      threshold_number = @settings[:lock_handling][:threshold_403]

      if threshold_number < 0
        max_lock(lockpick_type) + threshold_number
      else
        return threshold_number
      end
    end

    def lock_out_of_range?(lock_difficulty, with_lore: false)
      !can_pick_box(:vaalin, lock_difficulty, with_lore: with_lore)
    end

    def should_use_vaalin?
      always_use_vaalin = @picker.session_settings[:always_use_vaalin]
      mind_fried = ['must rest', 'saturated'].include?(checkmind)
      use_vaalin_when_fried = @settings[:lock_handling][:use_vaalin_when_fried]

      always_use_vaalin || (mind_fried && use_vaalin_when_fried)
    end

    def lore_bonus(spell, skill, selfcast = nil)
      selfcast = Spell[spell].known? if selfcast.nil?
      bonus = (Char.level/2).floor + (skill*0.1).floor + dex_bonus + (Spells.minorelemental/4).floor
      bonus = skill if bonus > skill
      bonus = (bonus/2).floor unless selfcast
      return bonus
    end

    def picking_tricks
      Dictionary.picking_tricks.select{|t, rank| lock_mastery_ranks >= rank }.keys
    end

    def pick_command(box)
      box_id = box.id
      if box.noun =~ /plinite/
        return "extract ##{box_id}"
      end
      if picking_tricks.any? && @settings[:lock_handling][:picking_trick]
        trick = @settings[:lock_handling][:picking_trick].strip if Dictionary.picking_tricks.include?(@settings[:lock_handling][:picking_trick].strip)
        trick = picking_tricks.sample if @settings[:lock_handling][:picking_trick].strip == 'random'
        trick = picking_tricks.last if @settings[:lock_handling][:picking_trick].strip == 'latest'

        return "pick ##{box_id}" unless trick
        "lm ptrick #{trick} ##{box_id}"
      else
        "pick ##{box_id}"
      end
    end

    def clear_hands(keep = [])
      @inventory_manager.clear_hands(keep)
    end

    def cast_404_if_needed(trap_difficulty, failed_attempt = false)
      if needs_disarm_lore?(trap_difficulty, failed_attempt) && knows_404? && !Spell[404].active?
        if !Spell[404].affordable?
          echo "Waiting for mana"
          wait_while{ !Spell[404].affordable? }
        end

        Spell[404].cast
        sleep 1
        cast_404_if_needed(trap_difficulty, failed_attempt) unless Spell[404].active?

      end
    end

    def cast_403_if_needed(lockpick_type, lock_difficulty)
      if needs_picking_lore?(lockpick_type, lock_difficulty) && knows_403? && !Spell[403].active?
        if !Spell[403].affordable?
          echo "Waiting for mana"
          wait_while{ !Spell[403].affordable? }
        end
        Spell[403].cast
        sleep 1
        cast_403_if_needed(lockpick_type, lock_difficulty) unless Spell[403].active?
      end
    end

    def cast_407_if_needed(box_id, force = false)

      if force || @settings[:lock_handling][:always_407]

			  wait_until { checkmana >= 10 }

        Spell[403].cast unless @settings[:lock_handling][:use_403] == 'Never' || Spell[403].active?
        Spell[407].cast(box_id)
      end
    end

    def cast_408_if_needed(box_id, trap_data, force = false)
      return false if trap_data[:type] == :sulpher # Can't 408 sulpher traps.

      # Don't 408 if it wouldn't be 100% safe -- if the user doesn't want to risk it.
      return false if %i(sphere crystal scale acid fire spores rods boomer).include?(trap_data[:type]) && @settings[:trap_handling][:only_408_safe]

      if force || @settings[:lock_handling][:always_408]

			  wait_until { checkmana >= 12 }

        Spell[404].cast unless @settings[:trap_handling][:use_404] == 'Never' || Spell[404].active?
        Spell[408].cast(box_id)
      end
    end

    def cast_maintenance_spells_if_needed(cast_for)
      mana_budget = 0
      cast_list = []

      if cast_for == 'locks'

        if @settings[:lock_handling][:maintain_205] && Spell[205].known? && !Spell[205].active?
          mana_budget += 5
          cast_list << 205
        end

        if @settings[:lock_handling][:maintain_506] && Spell[506].known? && !Spell[506].active?
          mana_budget += 6
          cast_list << 506
        end
      elsif cast_for == 'traps'
        if @settings[:trap_handling][:maintain_402] && Spell[402].known? && !Spell[402].active?
          mana_budget += 2
          cast_list << 402
        end

        if @settings[:trap_handling][:maintain_613] && Spell[613].known? && !Spell[613].active?
          mana_budget += 3
          cast_list << 613
        end

        if @settings[:trap_handling][:maintain_1006] && Spell[1006].known? && !Spell[1006].active?
          mana_budget += 6
          cast_list << 1006
        end
      end

      wait_while { checkmana <= mana_budget }
      cast_list.each{|spell| Spell[spell].cast }
    end

    def can_use_calipers?
      lock_mastery_ranks >= Dictionary.lock_mastery_skill_map[:use_calipers]
    end

    def can_calibrate_calipers?
      lock_mastery_ranks >= Dictionary.lock_mastery_skill_map[:workshop_calibrate_calipers]
    end

    def can_field_calibrate_calipers?
      lock_mastery_ranks >= Dictionary.lock_mastery_skill_map[:field_calibrate_calipers]
    end

    def can_repair_lockpicks?(vaalin: false)
      k = vaalin ? :repair_vaalin_lockpicks : :repair_lockpicks
      lock_mastery_ranks >= Dictionary.lock_mastery_skill_map[k]
    end

    def can_relock_boxes?
      lock_mastery_ranks >= Dictionary.lock_mastery_skill_map[:relock_boxes]
    end

    def can_wedge_boxes?
      lock_mastery_ranks >= Dictionary.lock_mastery_skill_map[:wedge_boxes]
    end


    def has_repair_wire?(type)
      @inventory_manager.has_repair_wire?(type)
    end
    def has_calipers?
      @inventory_manager.has_calipers?
    end

    def has_wedges?
      @inventory_manager.has_wedges?
    end

    def has_cottonballs?
      @inventory_manager.has_cottonballs?
    end

    def has_putty?
      @inventory_manager.has_putty?
    end

    def has_dagger?
      @inventory_manager.has_dagger?
    end

    def has_vials?
      @inventory_manager.has_vials?
    end

    def has_broken_lockpicks?
      @inventory_manager.has_broken_lockpicks?
    end

    def knows_404?
      Spell[404].known?
    end

    def knows_403?
      Spell[403].known?
    end

    def knows_407?
      Spell[407].known?
    end

    def knows_408?
      Spell[408].known?
    end

    def repair_lockpick(lockpick_id)
      fput "lm repair ##{lockpick_id}"
    end

    def say_scarab_found
      phrase = @settings[:speech_and_misc][:scarab_found_speech].sample
      return false if phrase.empty?
      fput "say #{phrase}"
    end

    def say_scarab_on_ground
      phrase = @settings[:speech_and_misc][:scarab_on_ground_speech].sample
      return false if phrase.empty?
      fput "say #{phrase}"
    end

    def say_scarab_safe
      phrase = @settings[:speech_and_misc][:scarab_safe_speech].sample
      return false if phrase.empty?
      fput "say #{phrase}"
    end

    def say_ready_for_boxes
      phrase = @settings[:speech_and_misc][:ready_for_boxes_speech].sample
      return false if phrase.empty?
      fput "say #{phrase}"
    end

    def say_cant_open_box
      phrase = @settings[:speech_and_misc][:cant_open_box_speech].sample
      return false if phrase.empty?
      fput "say #{phrase}"
    end

    private

    def parse_guild_info
      @lock_mastery_ranks = 0
      info_parser_hook = 'rpick_guild_info_parser_hook'

      guild_info_parser = Proc.new do |server_string|
        if server_string =~ /(Click \<a.*\>GLD MENU\<\/a\> for additional commands|You have no guild affiliation)/
          DownstreamHook.remove(info_parser_hook)
        end

        if server_string =~ /You have (\d+) ranks in the Lock Mastery skill/
          @lock_mastery_ranks = $1.to_i
        end

        if server_string =~ /You are a Master of Lock Mastery/
          @lock_mastery_ranks = 63
        end

        nil
      end

      DownstreamHook.add(info_parser_hook, guild_info_parser)

      toggle_echo
      silence_me
      fput "gld"
      silence_me
      toggle_echo
    end
  end
end
