# This class encapsulates any activities that the script supports that are not
# directly related to opening boxes. Things like calibrating calipers, repairing
# lockpicks, depositing/withdrawing silvers from the bank and so on.

module Rpick
  class AncillaryActions
    def initialize(picker, script = nil)
      @picker = picker
      @script = script
    end

    def pick_test
      echo @picker.settings[:lock_handling][:unpickable_box_action]
      #bs = Struct.new(:id)
      #box = bs.new(42)
      #lh = Rpick::LockHandler.new(box, @picker)
      #lh.lock_data = {
        #current_caliper_read: 415,
        #current_lock_read: nil,
      #}

      #lh.get_best_lockpick
    end

    def preflight_check
      woundables = %w(
        arms limbs torso back leftHand
        rightHand head rightArm abdomen
        leftEye leftArm chest leftFoot
        rightFoot rightLeg
        neck leftLeg nsys rightEye)
      has_wounds = false
      session_type = @picker.session_settings[:workflow]
      woundables.each{|w| has_wounds = Wounds.send(w) > 0 }
      respond "#################################################"
      respond "             RPick Preflight Check          "
      respond "               Workflow: (#{session_type})  "
      respond "                                            "
      respond "                                            "
      if has_wounds
      respond " You're currently hurt. that could affect   "
      respond " your ability to deal with traps and locks  "
      respond " "
      end
      respond " Your settings for this session are:        "
      if @picker.session_settings[:always_use_vaalin]
      respond "   Always Using Vaalin                        "
      end
      if @picker.session_settings[:start_with_copper]
      respond "   Starting With Copper                        "
      end
      if @picker.session_settings[:loot_from_ground]
      respond "   Looting From Ground                         "
      end
      if @picker.session_settings[:relock_boxes]
      respond "   Relocking Boxes                         "
      end
      if @picker.session_settings[:disarm_only]
      respond "   Only Disarming                         "
      end
      if @picker.settings[:speech_and_misc][:remove_armor]
      respond " Removing Armor To Pick"
      end
      respond " "
      respond " Max Lock You Will Attempt: "
      respond "         #{@picker.max_lock_attempt}"
      respond " Max Trap You Will Attempt: "
      respond "         #{@picker.max_trap_attempt}"
      respond " Missing Containers:"
      respond "      Toolkit: #{@picker.inventory[:containers][:locksmith_container]}" unless @picker.inventory_manager.has_toolkit?
      respond "      Lockpicks: #{@picker.inventory[:containers][:lockpick_container]}}" unless @picker.inventory_manager.has_lockpick_container?
      respond "      Broken Lockpicks: #{@picker.inventory[:containers][:broken_lockpick_container]}" unless @picker.inventory_manager.has_broken_lockpick_container?
      respond "      Dagger Sheath: #{@picker.inventory[:containers][:dagger_sheath]}" unless @picker.inventory_manager.has_dagger_sheath?
      respond "      Scarabs: #{@picker.inventory[:containers][:scarab_container]}" unless @picker.inventory_manager.has_scarab_container?
      respond "      Loot: #{@picker.inventory[:containers][:scarab_container]}" unless @picker.inventory_manager.has_loot_container?
      if @picker.can_wedge_boxes?
      respond "      Wedges: #{@picker.inventory[:containers][:wedge_container]}" unless @picker.inventory_manager.has_wedge_container?
      end
      respond " "
      respond " Disarming Tools:"
      respond "   Putty Remaining: #{@picker.inventory[:putty_count]}"
      respond "   Cottonballs Remaining: #{@picker.inventory[:cottonball_count]}"
      respond "   Acid Vials Remaining: #{@picker.inventory[:vial_count]}"
      if @picker.can_wedge_boxes?
      respond "   Wedges Remaining: #{@picker.inventory[:wedge_count]}"
      end
      respond "   Accessible Dagger: #{@picker.inventory[:dagger][:name]}"
      if @picker.can_use_calipers?
      respond "   Accessible Calipers: #{@picker.inventory[:calipers][:name]}"
      respond " "
      end
      if @picker.inventory_manager.missing_lockpicks.any?
        respond " Missing Lockpicks:"
        @picker.inventory_manager.missing_lockpicks.each do |ml|
          respond "   #{ml}"
        end
      end
      if @picker.inventory_manager.broken_lockpicks.any?
      respond " Broken Lockpicks:"
      @picker.inventory_manager.broken_lockpicks.each do |bl|
        respond "   #{bl[:name]}"
      end
      end
      respond "#################################################"

      respond "Do you wish to proceed with these settings?"
      respond "Type `;send yes` to continue"
      respond "Type `;send no` to abort"
      line = get until line.strip =~ /^yes|no$/i

      if line =~ /no/
        exit
      end
    end

    def calibrate_calipers
      if !@picker.can_calibrate_calipers?
        echo "Sorry, you aren't able to calibrate calipers yet!"
        return false
      end

      return calibration_loop if @picker.can_field_calibrate_calipers?

      respond '#######################################################'
      respond '                    Rpick                              '
      respond "You can't field calibrate calipers yet!"
      respond "But all is not lost! Type `;send yes` to"
      respond "travel to the nearest rogue workshop and"
      respond "calibrate your calipers there! You'll be"
      respond "brought right back here when you're done!"
      respond "If you'd prefer to skip calibration, type"
      respond "`;send no`"
      respond ""
      respond "If you would like to avoid seeing this message"
      respond "in the future, disable the `calibrate_before_startup`"
      respond "and/or the `calibrate_after` options in settings."
      respond '#######################################################'
      line = get until line.strip =~ /^yes|no$/i

      if line =~ /no/
        return true
      end

      target_room = Room.current.find_nearest(Dictionary.guild_workshop_locations)

      go_do_and_return(target_room) do
        fput "go tool"
        calibration_loop
      end
    end

    def deposit_silvers
      deposit_silvers_at = @picker.settings[:speech_and_misc][:deposit_silvers_when]
      return false if deposit_silvers_at == 'Never'
      enc_index = Dictionary.encumbrance_map.index(checkencumbrance)
      set_index = Dictionary.encumbrance_map.index(deposit_silvers_at)

      if enc_index >= set_index
        go_do_and_return('bank') do
          fput "deposit all"
        end
      end

    end

    def refill_toolkit
      go_do_and_return('locksmith') do
        order_number = nil

        fput "order"
        while line = get
          if line =~ /\d+.*\s{2}(\d+).*locksmith\'s/
            order_number = $1
          elsif line =~ /(\d+).*locksmith\'s/
            order_number = $1
          end
          break if line =~ /You can APPRAISE/
        end

        if !order_number
          echo "This locksmith doesn't sell a toolkit!"
          return false
        end

        fput "stow all"
        fput "order #{order_number}"
        purchase_result = dothistimeout "buy", 1, /(do not have enough silver|Sold for (.*) silvers)/

        if purchase_result =~ /do not have enough silver/
          echo "You need money to make this purchase. Get some silvers and try again."
          return false
        end

        fput "open ##{GameObj.right_hand.id}"
        fput "swap"
        fput "remove ##{@picker.inventory[:containers][:locksmith_container][:id]}"
        fput "bundle"
        fput "wear ##{@picker.inventory[:containers][:locksmith_container][:id]}"


        trash_container = GameObj.loot.find { |trash| trash.name =~ Dictionary.trash_container_regex }

        if trash_container
          fput "put ##{GameObj.left_hand.id} in ##{trash_container.id}"
        else
          fput "drop ##{GameObj.left_hand.id}"
        end
      end

      echo "Toolkit topped off"
    end

    def repair_lockpicks
      unless @picker.can_repair_lockpicks?
        echo "You don't know how to repair lockpicks!"
        return false
      end

      unless @picker.inventory_manager.broken_lockpicks.any?
        echo "You don't have any broken lockpicks."
      end

      target_room = Room.current.find_nearest(Dictionary.guild_workshop_locations)

      go_do_and_return(target_room) do
        fput "go tool"

        total_price = price_lockpick_repair(@picker.inventory_manager.broken_lockpicks)

        coin_amount = 0
        res = dothistimeout "wealth", 2, Dictionary.wealth_check_regex
        coin_amount = $1.gsub(',', '').to_i if res =~ Dictionary.coin_amount_regex

        if coin_amount.to_i < total_price

          fput "out"
          return false unless withdraw_money(total_price)
          fput "go tool"
        end

        @picker.inventory_manager.broken_lockpicks.each do |lockpick|
          repair_lockpick(lockpick)
        end
        fput "out"
      end

      echo "Lockpick repair complete"
    end

    private

    def withdraw_money(amount)
      go_do_and_return('bank') do
        fput "deposit all"
        withdraw_result = dothistimeout "withdraw #{amount} silvers", 1, /(don't seem to have that much|hands you .* silvers)/

        if withdraw_result =~ /don't seem to have that much/
          echo "You don't have enough money to make this withdraw!"
          return false
        end
      end
    end

    def price_lockpick_repair(lockpicks)
      fput "read sign"
      price = 0

      while line = get
        break if line =~ /\\\-\-\-\-/

        lockpicks.each do |l|
          type = l[:type].to_s

          if line =~ /#{type} wire .* (\d+) \|/ && !@picker.has_repair_wire?(l[:type])
            price += $1.to_i
          end

        end
      end

      price
    end

    def repair_lockpick(lockpick)
      fput "get ##{lockpick[:id]}"
      wire = nil

      if !@picker.has_repair_wire?(lockpick[:type])
        fput "read sign"
        while line = get
          break if line =~ /\\\-\-\-\-/
          type = lockpick[:type].to_s

          if line =~ /(\d+)\.\).*#{type} wire .* (\d+) \|/
            item_number = $1
            fput "order #{item_number}"
            fput "buy"
            break
          end
        end
      else
        wire = @picker.inventory_manager.get_wire_of_type(lockpick[:type])
        fput "get ##{wire[:id]}"
      end

      result = dothistimeout "lm repair ##{lockpick[:id]}", 2, Dictionary.lockpick_repair_result_regex

      if result =~ Dictionary.lockpick_repair_success_regex
        waitrt?
        fput "put ##{lockpick[:id]} in ##{@picker.inventory[:containers][:lockpick_container][:id]}"

        if wire
          @picker.inventory_manager.use_wire(wire)
        end
      end

      if result =~ Dictionary.lockpick_repair_failure_regex
        waitrt?
        echo "Could not repair #{lockpick[:name]}"
        fput "put ##{lockpick[:id]} in ##{@picker.inventory[:containers][:broken_lockpick_container][:id]}"
      end
    end

    def calibration_loop
      fput "get ##{@picker.inventory[:calipers][:id]}"

      matcher = Dictionary.calipers_calibrated_regex

      line = nil

      while line !~ matcher
        line = fput "lm calibrate ##{@picker.inventory[:calipers][:id]}"
        waitrt?
      end

      fput "put ##{@picker.inventory[:calipers][:id]} in ##{@picker.inventory[:containers][:locksmith_container][:id]}"
    end

    def go_do_and_return(target_room_id, &block)
      current_room_id = Room.current.id
      start_script('go2', [target_room_id])
      wait_while { running? 'go2' }
      yield
      start_script('go2', [current_room_id])
      wait_while { running? 'go2' }
    end

  end
end

