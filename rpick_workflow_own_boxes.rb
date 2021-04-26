module Rpick
  module Workflows
    class OwnBoxes < Workflow

      def run
        @ancillary = AncillaryActions.new(@picker, @script)
        @picker.clear_hands
        check_for_boxes
        sleep 1

        @boxes.each do |box|
          @box_id = box[:id]
          get_box

          handle_box && !@picker.session_settings[:disarm_only]  ? return_open_box : return_locked_box

          if @picker.wild_measure_miss && @picker.settings[:lock_handling][:calibrate_on_wild_miss]
            echo "Badly mis-measured the last lock. Calibrating calipers"
            @ancillary.calibrate_calipers
          end
        end
      end

      # Check inventory for boxes
      def check_for_boxes
        @boxes = []
        box_parser_hook = 'rpick_box_parser_hook'

        box_parser = Proc.new do |server_string|
          if server_string =~ /\d+ items displayed/
            DownstreamHook.remove(box_parser_hook)
          elsif server_string =~ Dictionary.box_finder_regex
            box_id   = $1
            box_noun = $2
            box_name = $3
            @boxes << { id: box_id, noun: box_noun, name: box_name }
            nil
          else
            nil
          end
        end

        DownstreamHook.add(box_parser_hook, box_parser)
        fput "inv full"
      end

      # Get one box from the list
      def get_box
        @picker.clear_hands
        fput "get ##{@box_id}"
        @current_box = GameObj.right_hand.id == @box_id ? GameObj.right_hand : GameObj.left_hand
      end

      # Empty into stow sack, then stow the empty
      def return_open_box
        if @current_box.name =~ /plinite/
          fput "pluck ##{@current_box[:id]}"
          fput "stow all"
        else
          fput "open ##{@current_box[:id]}"
          fput "get coins"
          fput "empty ##{@current_box[:id]} into ##{@picker.inventory[:containers][:loot_container][:id]}"
          fput "stow ##{@current_box[:id]}"
        end
      end

      # Stow the unopenable box
      def return_locked_box
        fput "stow ##{@current_box[:id]}"
      end
    end
  end
end
