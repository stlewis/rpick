module Rpick
  module Workflows
    class GroundBoxes < Workflow
      def run
        @ancillary = AncillaryActions.new(@picker, @script)
        @picker.clear_hands
        boxes = GameObj.loot.select{|l| l.noun =~ Dictionary.box_noun_regex }
        boxes.each do |box|
          @current_box = box
          get_box
          handle_box && !@picker.session_settings[:disarm_only]  ? return_open_box : return_locked_box

          if @picker.wild_measure_miss && @picker.settings[:lock_handling][:calibrate_on_wild_miss]
            echo "Badly mis-measured the last lock. Calibrating calipers"
            @ancillary.calibrate_calipers
          end
        end
      end

      def get_box # obtain a box to work on
        return true # No-op -- the boxes are on the ground
      end

      def return_open_box # return a succesfully handled box
        if @picker.session_settings[:loot_from_ground]
          if @current_box[:name] =~ /plinite/
            fput "pluck ##{@current_box[:id]}"
            fput "get ##{@current_box[:id]}"
            fput "stow all"
          else
            fput "get ##{@current_box[:id]}"
            fput "open ##{@current_box[:id]}"
            fput "get coins"
            waitrt?

            fput "empty ##{@current_box[:id]} into ##{@picker.inventory[:containers][:loot_container][:id]}"
            waitrt?
            fput "stow ##{@current_box[:id]}"
          end
        end

        return true # No-op, the box is on the ground
      end

      def return_locked_box # return a box that could not be successfully handled
        if @picker.session_settings[:loot_from_ground]
          # This is our box, we should grab and stow
          fput "get ##{@current_box[:id]}"
          fput "stow ##{@current_box[:id]}"
        end

        return true # No-op, the box is on the ground
      end
    end

  end
end
