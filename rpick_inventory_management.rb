# This class handles inventory concerns related to locksmithing. It ensures that the picker
# has all inventory items necessary for all tasks.
module Rpick
  class InventoryManagement
    attr_reader :inventory, :user_settings

    def initialize(user_settings)
      @user_settings = user_settings
      parse_inventory
      check_for_broken_picks
    end

    def check_toolkit
      parse_toolkit_contents
    end

    def broken_lockpicks
      @inventory[:broken_lockpicks]
    end

    def missing_lockpicks
      missing = []

      @inventory[:lockpicks].each do |type, picks|
        if (picks.nil? || picks.empty?)
          using_store_bought = @user_settings[:lockpicks][:use_store_bought_lockpicks]

          missing << type if !using_store_bought && !@user_settings[:lockpicks][type].empty?
          missing << type if using_store_bought
        end
      end

      return missing
    end

    def box_in_hand(box_id)
      box_in_right = GameObj.right_hand.id == box_id ? GameObj.right_hand.id : nil
      box_in_left  = GameObj.left_hand.id == box_id ? GameObj.left_hand.id : nil
      holding_box_id = box_in_right ? box_in_right : box_in_left

      return holding_box_id
    end

    def clear_hands(keep = [])
      waitrt?
      right_hand_has = GameObj.right_hand
      left_hand_has  = GameObj.left_hand

      clear_hand(right_hand_has, keep) if right_hand_has
      sleep 1
      clear_hand(left_hand_has, keep) if left_hand_has
    end

    def clear_hand(hand_has, keep)
      return true unless hand_has.id
      return true if keep.include?(hand_has.id)

      return store_vial(hand_has.id) if is_vial?(hand_has)
      chosen_container = nil

      chosen_container = @inventory[:containers][:scale_trap_weapon_container][:id] if is_dagger?(hand_has)
      chosen_container = @inventory[:containers][:lockpick_container][:id] if is_lockpick?(hand_has)
      chosen_container = @inventory[:containers][:wedge_container][:id] if is_wedge?(hand_has)
      chosen_container = @inventory[:containers][:locksmith_container][:id] if is_calipers?(hand_has)
      chosen_container = @inventory[:containers][:scarab_container][:id] if is_scarab?(hand_has)

      if chosen_container
        fput "put ##{hand_has.id} in ##{chosen_container}"
      else
        fput "stow ##{hand_has.id}"
      end
    end

    def has_toolkit?
      !@inventory[:containers][:locksmith_container].empty?
    end

    def has_scarab_container?
      !@inventory[:containers][:scarab_container].empty?
    end

    def has_loot_container?
      !@inventory[:containers][:loot_container].empty?
    end

    def has_dagger?
      !@inventory[:dagger].empty?
    end

    def has_repair_wire?(type)
      @inventory[:repair_wires][type].any?
    end

    def is_dagger?(thing)
      thing.id == @inventory[:dagger][:id]
    end

    def has_lockpick?(lockpick_name)
      lockpick_names = @inventory[:lockpicks].values.map{|v| v.map{|l| l[:name] } }.flatten
      lockpick_names.include?(lockpick_name)
    end

    def has_lockpick_type?(lockpick_type)
      !@inventory[:lockpicks][lockpick_type].empty?
    end

    def is_lockpick?(thing)
      custom_pick_ids = @inventory[:lockpicks].values.map{|picks| picks.map{|pk| pk[:id] } }.flatten
      store_bought_pick_names = Dictionary.store_bought_lockpicks.values.flatten.uniq

      custom_pick_ids.include?(thing.id) || store_bought_pick_names.include?(thing.name)
    end

    # Try to fetch a lockpick corresponding to the requested type.
    # If such a lockpick cannot be found, call again with the next
    # tier up.
    def get_lockpick_of_type(lockpick_type)
      if has_lockpick_type?(lockpick_type)
        return @inventory[:lockpicks][lockpick_type].first
      else
        if lockpick_type == :vaalin
          return false
        end

        next_type_index = Dictionary.lockpick_modifiers.keys.index(lockpick_type) + 1
        next_type = Dictionary.lockpick_modifiers.keys[next_type_index]
        get_lockpick_of_type(next_type)
      end
    end

    def get_wire_of_type(type)
      if has_repair_wire?(type)
        return @inventory[:repair_wires][type].first
      else
        echo "No wire of that type!"
      end
    end

    def use_wire(wire)
      @inventory[:repair_wires][wire[:type]].delete(wire)
    end

    def has_wedges?
      @inventory[:wedge_count] > 0
    end

    def is_wedge?(thing)
      thing.noun == 'wedge'
    end

    def is_scarab?(thing)
      thing.noun =~ /scarab/
    end

    def has_vials?
      @inventory[:vial_count] > 0
    end

    def is_vial?(thing)
      thing.noun == 'vial'
    end

    def has_cottonballs?
      @inventory[:cottonball_count] > 0
    end

    def has_putty?
      @inventory[:putty_count] > 0
    end

    def has_calipers?
      !@inventory[:calipers].nil?
    end

    def is_calipers?(thing)
      @inventory[:calipers][:id] == thing.id
    end

    def has_dagger_sheath?
      !@inventory[:containers][:scale_trap_weapon_container].nil?
    end

    def has_lockpick_container?
      !@inventory[:containers][:lockpick_container].nil?
    end

    def has_broken_lockpick_container?
      !@inventory[:containers][:broken_lockpick_container].nil?
    end

    def has_wedge_container?
      !@inventory[:containers][:wedge_container].nil?
    end

    def has_broken_lockpicks?
      @inventory[:broken_lockpicks].any?
    end

    def handle_broken_pick(lockpick_id)
      broken_pick = @inventory[:lockpicks].select{|k, v| v.map{|lp| lp[:id] }.include?(lockpick_id) }.first.last.first
      broken_pick[:broken] = true
      @inventory[:broken_lockpicks] << broken_pick
      @inventory[:lockpicks][broken_pick[:type]].delete(broken_pick)

      fput "put ##{lockpick_id} in ##{@inventory[:containers][:broken_lockpick_container][:id]}"
    end

    private

    def parse_inventory
      toggle_echo
      silence_me
      @inventory = {
        lockpicks: nil,
        repair_wires: {},
        broken_lockpicks: [],
        containers: {
          loot_container: nil,
          lockpick_container: nil,
          broken_lockpick_container: nil,
          wedge_container: nil,
          scale_trap_weapon_container: nil,
          locksmith_container: nil
        },
        putty_count: 0,
        cottonball_count: 0,
        wedge_count: 0,
        vial_count: 0,
        dagger: nil,
        calipers: nil
      }

      inventory_parser_hook = 'rpick_inventory_parser_hook'
      inventory_parser = Proc.new do |server_string|
        if server_string =~ /\d+ items displayed/
          DownstreamHook.remove(inventory_parser_hook)
        elsif server_string =~ Dictionary.item_link_regex
          parse_item($1, $2, $3)
          nil
        elsif server_string =~ /You are currently wearing and carrying\:/
          nil
        else
          server_string
        end
      end

      DownstreamHook.add(inventory_parser_hook, inventory_parser)
      fput "inv full"
      sleep 1
      #Toolkit contents
      parse_toolkit_contents if @inventory[:containers][:locksmith_container]
      sleep 1
      silence_me
      toggle_echo
    end

    def parse_item(item_id, item_noun, item_name)
      # Set containers
      @user_settings[:containers_and_equipment].keys.each do |container_kind|
        next if container_kind == :auto_bundle_vials
        if item_name == @user_settings[:containers_and_equipment][container_kind].strip
          @inventory[:containers][container_kind] = { id: item_id, name: item_name }
        end
      end

      # Miscellaneous tools and armor
      @inventory[:calipers] = { id: item_id, name: item_name } if item_noun == 'calipers'
      @inventory[:wedge_count] += 1 if item_noun =~ /wedge/
      @inventory[:dagger]   = { id: item_id, name: item_name } if item_name == @user_settings[:containers_and_equipment][:scale_trap_weapon].strip
      @inventory[:worn_armor] = { id: item_id, name: item_name } if item_name == @user_settings[:speech_and_misc][:remove_armor]

      # Lockpicks
      @inventory[:lockpicks] ||= Dictionary.lockpick_modifiers.keys.reduce({}) do |hsh, lockpick_type|
        hsh[lockpick_type] = []
        hsh
      end

      # Repair wires
      if item_name =~ /wire/
        Dictionary.lockpick_modifiers.keys.each do |wire_type|
          @inventory[:repair_wires][wire_type] ||= []

          if item_name =~ /#{wire_type.to_s} wire/
            @inventory[:repair_wires][wire_type] << { id: item_id, name: item_name, type: wire_type }
          end
        end
      end

      @user_settings[:lockpicks].each do |lockpick_type, lockpicks|
        next if lockpick_type == :use_store_bought_lockpicks # Because not actually a lockpick!

        if lockpicks.include?(item_name)
          @inventory[:lockpicks][lockpick_type] << { id: item_id, name: item_name, type: lockpick_type }
        end
      end

      if @user_settings[:lockpicks][:use_store_bought_lockpicks]
        Dictionary.store_bought_lockpicks.each do |lockpick_type, lockpick_names|
          if lockpick_names.include?(item_name)
            lockpick_data = { id: item_id, name: item_name, type: lockpick_type }
            unless @inventory[:lockpicks][lockpick_type].include?(lockpick_data)
              @inventory[:lockpicks][lockpick_type] << lockpick_data
            end
          end
        end
      end
    end

    def parse_toolkit_contents
      toolkit_parser_hook = 'rpick_toolkit_parser_hook'
      toolkit_parser = Proc.new do |server_string|
        if server_string =~ /Peering into the (.*), you see/
          @inventory[:putty_count] = server_string.match(Dictionary.putty_remaining_regex)[1].to_i || 0
          @inventory[:cottonball_count] = server_string.match(Dictionary.cotton_balls_remaining_regex)[1].to_i || 0
          matched_vials = server_string.match(Dictionary.vials_remaining_regex)[1]
          @inventory[:vial_count] = matched_vials == 'a single' ? 1 : matched_vials.to_i || 0
          DownstreamHook.remove(toolkit_parser_hook)
        end
      end

      DownstreamHook.add(toolkit_parser_hook, toolkit_parser)
      fput "look in ##{@inventory[:containers][:locksmith_container][:id]}"
    end

    def store_vial(vial_id)
      echo "Attempting to store a vial"
      echo @user_settings[:containers_and_equipment][:auto_bundle_vials]
      if @user_settings[:containers_and_equipment][:auto_bundle_vials] && @inventory[:vial_count].to_i < 10
        fput "stow #{vial_id}"
        fput "stow all"
        fput "remove ##{@inventory[:containers][:locksmith_container][:id]}"
        fput "get ##{vial_id}"
        fput "bundle"
        fput "wear ##{@inventory[:containers][:locksmith_container][:id]}"
      else
        fput "stow ##{vial_id}"
      end
    end

    def check_for_broken_picks
      # Go through the list of picks. glance at them. If they appear to be broken,
      # mark them as such.
      broken_pick_parser_hook = 'rpick_broken_pick_parser_hook'
      broken_pick_parser = Proc.new do |server_string|
        if server_string =~ /The <a exist\=\"(\d+)\" noun\=\"(.*)\"\>(.*)\<\/a\> appears to be broken/
          lockpick_id = $1
          handle_broken_pick(lockpick_id)
          nil
        elsif server_string =~ /You see nothing unusual/
          nil
        else
          server_string
        end
      end

      silence_me
      toggle_echo

      DownstreamHook.add(broken_pick_parser_hook, broken_pick_parser)
      @inventory[:lockpicks].each do |k, lockpicks|
        lockpicks.each do |lockpick|
          fput "look at ##{lockpick[:id]}"
        end
      end
      DownstreamHook.remove(broken_pick_parser_hook)

      toggle_echo
      silence_me
    end
  end
end
