# This module encapsulates any information that is static and other classes may
# need to reference. This includes things like lockpick modifiers, regular expressions
# for matching against various things in the game, lockpick names, workshop location
# room numbers and so on. The goal here is to capture all or most of the things that
# are unlikely to change in a central place where they're easy to reference when needed
# and simple to modify if the game _does_ change them for some reason

module Rpick
  module Dictionary

    def self.trap_detection_regexes
      {
        scarab:              /you spy a (.*) scarab/,
        needle:              /tiny hole next to the lock plate|nestled in a hole/,
        jaws:                /discolored oval ring/,
        sphere:              /sphere held in a metal bracket|tiny sphere/,
        crystal:             /dark crystal which seems imbedded|small crystal/,
        scales:              /hundreds of tiny metal scales|cord stretched between/,
        sulpher:             /rough, grainy substance/,
        cloud:               /vial of liquid and a tiny hammer/,
        acid:                /vial placed just past the tumblers/,
        springs:             /springs incorporated/,
        fire:                /vial of fire-red liquid and a tiny hammer/,
        spores:              /capped with a thin membrane|apears to be filled with a greenish powder/,
        plate:               /sealing it and preventing any access/,
        glyph:               /spiderweb-like scratches/,
        rods:                /push the two rods together|small metal rods/,
        boomer:              /strange white substance|inside chamber is lined with some unidentifiable substance/,
        clean:               /You discover no traps/,
        manually_disarmed:   /(bent in opposite directions|free of all obstructions|have been pushed out|seems to be empty now|avoid unwanted contact|sliced through|deflated bladder|bent back slightly|but it appears empty|plugged with something|melted through|may prevent any magical nature|prevent it from igniting|trap was here has been removed|seems to indicate cause for alarm|cotton has been pushed up against the vial|Looking closely into the keyhole of the lock, you spy a small metal housing, which appears to be empty|which has been completely plugged|striking range of the vial)/,
        magically_disarmed:  /(crimson|reddish|deep red) glow/,
        already_open:        /You blink in surprise as though just becoming aware/
      }
    end

    def self.plinite_detection_regex
      /It looks like it would be.*\(\-(\d+)\)\.|You struggle to determine the difficulty of the extraction \(somewhere between .* and \-(\d+)\)\.|the core has already been removed|unable to determine the difficulty of the extraction|You promptly discover that the core has already been extracted and merely needs to be PLUCKed/
    end

    def self.successful_plinite_detection_regex
      /(It looks like it would be.*\(\-(\d+)|difficulty of the extraction \(somewhere between .* and \-(\d+)\)\.)/
    end

    def self.plinite_core_removed_regex
      /You promptly discover that the core has already been removed\./
    end

    def self.box_accepted_regex
      /You accept (.*)'s offer and are now holding an? (.*)\./
    end

    def self.box_offered_regex
      /(.*) offers you an? (.*)\. .* to accept the offer/
    end

    def self.trash_container_regex
      /crate|barrel|wastebarrel|casket|bin|receptacle|basket/i
    end

    def self.item_link_regex
      /\<a exist\=\"(\d+)\" noun\=\"(.*)\"\>(.*)\<\/a\>/
    end

    def self.hand_check_regex
      /(\<a exist\=\"(\d+)\" noun\=\"(.*)\"\>(.*)\<\/a\>) in your (right|left) hand( and an? (\<a exist\=\"(\d+)\" noun\=\"(.*)\"\>(.*)\<\/a\>) in your left hand)?\./
    end

    def self.right_hand_regex
      /(\<a exist\=\"(\d+)\" noun\=\"(.*)\"\>(.*)\<\/a\>) in your right hand/
    end

    def self.left_hand_regex
      /(\<a exist\=\"(\d+)\" noun\=\"(.*)\"\>(.*)\<\/a\>) in your left hand/
    end

    def self.wealth_check_regex
      /You have (no silver|[\d\,]+) coins with you/
    end

    def self.coin_amount_regex
      /You have ([\d\,]+) coins with you/
    end

    def self.putty_remaining_regex
      /(\d+) pinch(es)? left/
    end

    def self.cotton_balls_remaining_regex
      /(\d+) little balls of cotton/
    end

    def self.vials_remaining_regex
      /((\d+)|a single) vials? of liquid/
    end

    def self.lockpick_repair_result_regex
      Regexp.union(lockpick_repair_success_regex, lockpick_repair_failure_regex)
    end

    def self.lockpick_repair_failure_regex
      /refuses to work free/
    end

    def self.lockpick_repair_success_regex
      /form a tight bond/
    end

    def self.disarm_success_regex
      /(manage to block|manage to pull|gently nudge the tiny gem|manage to grind down|blowing away in the wind|bend the weak metal|surrounding and protecting|pop them inside|should block whatever|hoping to alter|cannot be pressed together|prevent sparks when|ought to do it|plate covering the lock begins to melt away|carefully remove)/
    end

    def self.disarm_failure_regex
      /(built too tightly|You are not able to disarm the trap)/
    end

    def self.tripped_trap_regex
      /(horribly awry|you feel a tiny prick|sound like shattered crystal|tinkling sound from the lock|explodes in a bright flash|sound of glass shattering)/
    end

    def self.pick_result_regex
      Regexp.union(lock_read_regex, no_lock_read_regex, lock_success_regex, pick_bent_regex, pick_broken_regex, lock_already_open_regex)
    end

    def self.box_pop_success_regex
      /(it suddenly flies open|is already open)/
    end

    def self.box_pop_failure_regex
      /The .* vibrates slightly but nothing else happens/
    end

    def self.box_pop_disarm_success_regex
      /pulses once with a deep crimson light/
    end

    def self.box_pop_disarm_failure_regex
      /vibrates slightly but nothing else happens/
    end

    def self.pick_attempt_regex
      /You make an? .* attempt \(d100.*=(\d+)\)/
    end

    def self.lock_read_regex
      /About a \-(\d+) difficulty lock/
    end

    def self.trap_read_regex
      /It looks like an? (.*) trap \((about )?\-(\d+)\)/
    end

    def self.unsuccessful_caliper_read_regex
      /Maybe if you had a set of calipers/
    end

    def self.successful_caliper_read_regex
      /it looks to be an? (.*) lock \(-(\d+) in thief-lingo difficulty ranking\)/
    end

    def self.caliper_read_regex
      Regexp.union(unsuccessful_caliper_read_regex, successful_caliper_read_regex)
    end

    def self.no_lock_read_regex
      /You are not able to pick the lock|You make a fumbling attempt|little too hard and create an ugly new crack|retrieving the core is within your abilities/
    end

    def self.plinite_unextractable_regex
      /abilities are probably not sufficient to retrieve/
    end

    def self.lock_success_regex
      /You struggle with the .*\.  As you do, you get a sense that the .* has an? .* lock \(-(.*) thief-lingo difficulty ranking\)\.  Then\.\.\.CLICK!  It (opens|locks)!/
    end

    def self.plinite_success_regex
      /where it can be easily PLUCKed/
    end

    def self.pick_broken_regex
      /(You broke your lockpick|snapping off the tip|you realize you are using a broken lockpick)/
    end

    def self.pick_bent_regex
      /(end up bending the tip|weakened by the stress)/
    end

    def self.lock_already_open_regex
      /does not appear to be locked/
    end

    def self.box_finder_regex
      /\<a exist\=\"(\d+)\" noun\=\"(box|strongbox|coffer|chest|trunk|case)\"\>(.*)\<\/a\>/
    end

    def self.box_noun_regex
      /(box|strongbox|coffer|chest|trunk|case)/
    end

    def self.worker_box_regex
      /The client is offering a tip of ([\d\,]+) silvers? and mentioned it being from an? (.*) \(level (\d+)\)\.  The (box|strongbox|coffer|chest|trunk|case) is set up on/
    end

    def self.worker_box_already_available_regex
      /You should finish the job you're working on first/
    end

    def self.worker_success_regex
      /Here's your payment of ([\d\,]+) silvers|You aren't working on a job/
    end

    def self.worker_unsuccessful_regex
      /Too tough for ya, eh|You weren't able to get the lock huh/
    end

    def self.worker_wait_regex
      /(Why don't you rest your mind a bit|have any jobs for you at the moment|ask me again (.*)|think about this for a few minutes before|wait a bit longer before asking again)/
    end

    def self.calipers_calibrated_regex
      /(glow with calibration|could not be more perfectly calibrated)/
    end

    def self.worker_give_up_regex
      /If you want to give up, ASK me to CHECK it again within 30 seconds/
    end

    def self.worker_tip_too_high_regex
      /We don't have any jobs for you at the moment\.  Why don't you try again later/
    end

    def self.scarab_down_regex
      /nudge the scarab free/
    end

    def self.scarab_tripped_regex
      /buzzing of a tiny insect/
    end

    def self.wedge_result_regex
      /(splits away from the casing|takes massive damage|Wedge what\?|Roundtime)/
    end

    def self.wild_measure_miss_threshold
      50
    end

    def self.lockpick_modifiers
      {
        copper:  1.00,
        brass:   1.00,
        steel:   1.10,
        ivory:   1.20,
        gold:    1.20,
        silver:  1.30,
        mithril: 1.45,
        ora:     1.55,
        glaes:   1.60,
        laje:    1.75,
        vultite: 1.80,
        rolaren: 1.90,
        veniom:  2.20,
        invar:   2.25,
        alum:    2.30,
        golvern: 2.35,
        kelyn:   2.40,
        vaalin:  2.50
      }
    end

    def self.store_bought_lockpicks
      {
        copper: [
          'copper lockpick',
          'dark red copper lockpick',
          'wood-handled copper lockpick',
          'elm-handled thin copper lockpick',
          'polished copper lockpick',
          'crystal-inset red copper lockpick',
          'tarnished green copper lockpick',
          'burnished copper lockpick',
          'wire-wrapped copper lockpick',
          'opal-tipped bright copper lockpick',
        ],
        brass: [
          'brass lockpick',
          'silver-edged twisted brass lockpick',
          'blue-tinged tarnished brass lockpick'
        ],
        steel: [
          'steel lockpick',
          'twisted steel lockpick',
          'conch-inlaid watered steel lockpick',
          'tapered burnished steel lockpick',
          'ruby-inset blue steel lockpick',
          'slender steel lockpick',
          'quartz-inlaid blued steel lockpick',
          'slender black steel lockpick',
          'shiny steel glaesine-tipped lockpick',
          'plain steel lockpick',
          'ora-handled black steel lockpick',
        ],
        ivory:   [
          'ivory lockpick',
          'gold-edged pale ivory lockpick',
          'stained white ivory lockpick',
        ],
        gold: [
          'gold lockpick',
          'gleaming gold lockpick',
          'wire-wound lustrous gold lockpick',
          'tapered white gold lockpick',
          'silver-chased gold lockpick',
          'garnet-inset rose gold lockpick',
          'rune-etched muted gold lockpick',
          'twisted gold lockpick',
          'acid-etched gold lockpick',
          'chiseled rose gold lockpick',
        ],
        silver: [
          'silver lockpick',
          'etched silver-tipped lockpick',
          'dull brushed silver lockpick',
        ],
        mithril: [
          'mithril lockpick',
          'ivory-inlaid mithril lockpick',
          'twisted silvery mithril lockpick',
          'blue-veined grey mithril lockpick',
          'snail-capped mithril lockpick',
          'wood-handled mithril lockpick',
          'ruby-edged dark mithril lockpick',
          'blue-swirled mithril lockpick',
          'blackened mithril lockpick',
          'thin mithril-tipped lockpick',
          'acid-etched silvery mithril lockpick',
          'blue-hued wavy mithril lockpick',
        ],
        ora: [
          'ora lockpick',
          'platinum ora-tipped lockpick',
          'abalone-set ora lockpick',
          'silver-chased spiraled ora lockpick',
          'burnished ora lockpick',
          'opalescent ora lockpick',
          'thin wire green ora lockpick',
          'simple ora lockpick',
          'spirale white ora lockpick',
          'onyx-tipped grey ora lockpick',
          'pitted light grey ora lockpick',
        ],
        glaes: [
          'glaes-handled scrimshaw lockpick',
          'sturdy glaes lockpick',
          'chiseled black glaes lockpick',
          'slender rainbow glaes lockpick',
          'translucent glaes lockpick',
          'cerulean-hued wavy glaes lockpick',
          'glossy black glaes lockpick',
          'fine-toothed sparkling glaes lockpick',
          'gleaming dark glaes lockpick',
          'sea green glaes lockpick',
          'translucent golden glaes lockpick',
        ],
        laje:    [
          'laje lockpick',
          'ivory-tipped black laje lockpick',
          'deep amber colored laje lockpick',
        ],
        vultite: [
          'vultite lockpick'
        ],
        rolaren: [
          'rolaren lockpick',
          'petrified tiger fang lockpick',
          'pearl-handled rolaren lockpick',
          'silver-edged dark rolaren lockpick',
          'sapphire brushed rolaren lockpick',
          'opal-edged grey rolaren lockpick',
          'platinum and dark rolaren lockpick',
          'ruby-veined black rolaren lockpick',
          'shell-inlaid black rolaren lockpick',
        ],
        veniom: [
          'veniom lockpick',
          'silk-wrapped veniom lockpick'
        ],
        invar: [
          'invar lockpick',
          'jade-handled invar lockpick',
          'scallop-edged invar lockpick',
          'red-flecked dark invar lockpick',
          'blackened invar lockpick',
          'sharp frosted grey invar lockpick',
          'feystone-set invar lockpick',
          'bone-handled dark invar lockpick',
          'red-flecked black invar lockpick',
          'etched invar lockpick',
          'emerald-set etched invar lockpick',
          'opal-inlaid tarnished invar lockpick',
          'red-speckled sturdy invar lockpick',
        ],
        alum: [
          'alum lockpick',
          'opal-studded alum lockpick',
          'fine-toothed white alum lockpick',
          'slate grey narrow alum lockpick',
          'onyx-handled grey alum lockpick',
          'pearl-etched thin alum lockpick',
          'laje handled bent alum lockpick',
          'delicate silvery alum lockpick',
          'burnished golden alum lockpick',
          'slim blackened alum lockpick',
        ],
        golvern: [
          'golvern lockpick',
          'reinforced titian golvern lockpick',
          'burnished golvern lockpick',
          'tapering golvern-edged lockpick',
          'well-crafted narrow golvern lockpick',
        ],
        kelyn: [
          'kelyn lockpick',
          'slender kelyn lockpick',
          'streaked russet kelyn lockpick',
          'tapered white kelyn lockpick',
          'kelyn-tipped myklian scale lockpick',
          'fine-toothed red kelyn lockpick',
          'gold-chased kelyn lockpick',
          'tapered black kelyn lockpick',
          'polished golden kelyn lockpick',
        ],
        vaalin: [
          'vaalin lockpick',
          'etched black vaalin lockpick',
          'pearl-handled white vaalin lockpick',
          'diamond-edged black vaalin lockpick',
          'suede-wrapped vaalin lockpick',
          'ivory-tipped dark vaalin lockpick',
          'feystone-set swirled vaalin lockpick',
          'gold-etched pearly vaalin lockpick',
        ]
      }
    end

    def self.guild_workshop_locations
      [ '17978', '16574', '17960', '17881', '17387', '21187' ]
    end

    # NOTE This is mostly anecdotal and only here to specify a max lock cap if the user doesn't provide one.
    def self.theoretical_max_lock
      1500
    end

    # NOTE This is mostly anecdotal and only here to specify a max trap cap if the user doesn't provide one.
    def self.theoretical_max_trap
      600
    end

    def self.picking_tricks
      {
        spin: 1,
        twist: 10,
        turn: 20,
        twirl: 30,
        toss: 40,
        bend: 50,
        flip: 60
      }
    end

    def self.lock_mastery_skill_map
      {
        use_calipers: 6,
        workshop_calibrate_calipers: 10,
        wedge_boxes: 14,
        repair_lockpicks: 25,
        relock_boxes: 30,
        field_calibrate_calipers: 40,
        repair_vaalin_lockpicks: 60,
      }
    end

    def self.encumbrance_map
      [
        'Light',
        'Somewhat',
        'Moderate',
        'Significant',
        'Heavy',
        'Very Heavy',
        'Extreme',
        'Overloaded' ]
    end

    def self.head_state_map
      [
        'clear as a bell',
        'fresh and clear',
        'clear',
        'muddled',
        'becoming numbed',
        'numbed',
        'must rest',
      ]
    end

  end
end
