module Rpick
  module Workflows
    class LocksmithPoolBoxes < Workflow
      attr_reader :current_box, :table

      def run
        @ancillary = AncillaryActions.new(@picker, @script)
        worker_by_location
        table_by_location

        if !@worker
          echo "You aren't at a locksmith pool location! Get yourself to an appropriate location and run this script again"
          exit
        end
        @ancillary.deposit_silvers
        cycle
      end

      def cycle
        while true
          if @picker.settings[:speech_and_misc][:rest_at_state] != 'Never' && @picker.settings[:speech_and_misc][:pick_at_state] != 'Always'
            echo @picker.settings[:speech_and_misc][:rest_at_state]
            echo @picker.settings[:speech_and_misc][:pick_at_state]
            rest_for_head_state
          end

          get_box
          will_handle_box = true
          max_critter_level = @picker.settings[:locksmith_pool][:max_critter_level]
          will_handle_box = false if  max_critter_level > 0 && max_critter_level < @box_info[:critter_level].to_i
          will_handle_box && handle_box ? return_open_box : return_locked_box

          if @picker.wild_measure_miss && @picker.settings[:lock_handling][:calibrate_on_wild_miss]
            echo "Badly mis-measured the last lock. Calibrating calipers"
            @ancillary.calibrate_calipers
          end


          @ancillary.deposit_silvers

          if @picker.box_count > @picker.settings[:lock_handling][:calibrate_after]
            @picker.box_count = 0
            @picker.clear_hands
            @ancillary.calibrate_calipers
          end
        end
      end

      def get_box # obtain a box to work on
        @picker.clear_hands
        ask_command =  @picker.settings[:locksmith_pool][:tip_request] > 0 ? "ask ##{@worker.id} for job minimum #{tip_request}" : "ask ##{@worker.id} for job"

        res = dothistimeout ask_command, 2, Regexp.union(Dictionary.worker_wait_regex, Dictionary.worker_box_regex, Dictionary.worker_tip_too_high_regex, Dictionary.worker_box_already_available_regex)

        if res =~ Dictionary.worker_tip_too_high_regex && @picker.settings[:locksmith_pool][:tip_request] > 0
          sleep 15
          decrement_tip_request
          cycle
        end

        if res =~ Dictionary.worker_box_already_available_regex
          check_table_for_box
          return true
        end

        if res =~ Dictionary.worker_wait_regex
          wait_time = $2 =~ /about a minute/ ? 70 : 180
          echo "No boxes available. Waiting #{wait_time} seconds then trying again."
          sleep wait_time
          cycle
        end

        sleep 1

        if res =~ Dictionary.worker_box_regex
          @box_info = {
            tip_amount: $1,
            critter: $2,
            critter_level: $3,
            box_type: $4
          }

          check_table_for_box
          return true
        end

      end

      def decrement_tip_request
        decremented = @tip_request - @picker.settings[:locksmith_pool][:tip_decrement]
        base = @picker.settings[:locksmith_pool][:tip_request]
        minimum = @picker.settings[:locksmith_pool][:minimum_tip]

        @tip_request = decremented <  minimum ? base : decremented
      end

      def tip_request
        base_tip_request = @picker.settings[:locksmith_pool][:tip_request]
        @tip_request ||= base_tip_request
        @tip_request
      end

      def check_table_for_box
        @current_box = nil

        while !@current_box
          fput "look on ##{@table.id}"
          @current_box = @table.contents.find{|b| b.name =~ /#{checkname}/ }
          echo @current_box
        end

        @current_box
      end

      def return_open_box # return a succesfully handled box
        dothistimeout "ask ##{@worker.id} about check", 2, Dictionary.worker_success_regex
      end

      def return_locked_box # return a box that could not be successfully handled
        echo "Couldn't get this box, or won't because of settings. Returning to the worker"
        dothis "ask ##{@worker.id} about check", Dictionary.worker_give_up_regex
        sleep 1
        dothis "ask ##{@worker.id} about check", Dictionary.worker_unsuccessful_regex
      end

      def worker_by_location
        return 'worker' if Room.current.id == 28937
        Room.current.tags.find{|t|  t =~ /meta:boxpool:npc:(.*)/ }
        @worker = GameObj.npcs.find{|n| n.name == $1 }
      end

      def table_by_location
        Room.current.tags.find{|t|  t =~ /meta:boxpool:table:(.*)/ }
        @table = GameObj.loot.find{|n| n.name == $1 }
      end

      def rest_for_head_state
        current_head_state_index = Dictionary.head_state_map.index(checkmind)
        rest_at_head_state_index = Dictionary.head_state_map.index(@picker.settings[:speech_and_misc][:rest_at_state].downcase)
        pick_at_head_state_index = Dictionary.head_state_map.index(@picker.settings[:speech_and_misc][:pick_at_state].downcase)

        if current_head_state_index >= rest_at_head_state_index
          echo "Resting until head clears"
          wait_until do
            chsi = Dictionary.head_state_map.index(checkmind)
            chsi <= pick_at_head_state_index
          end
        end
      end

    end


  end
end
