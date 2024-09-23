SMODS.meta_tags = {
    -- TODO: fill me. Kept as a separate list for convience while making it
}

local vanilla_joker_tags = {
    j_joker = {
        SMODS.meta_tags.plus_mult,
    },
    j_greedy_joker = {
        SMODS.meta_tags.plus_mult,
        SMODS.meta_tags.suit_diamonds,
        SMODS.meta_tags.suit,
    },
    j_lusty_joker = {
        SMODS.meta_tags.plus_mult,
        SMODS.meta_tags.suit_hearts,
        SMODS.meta_tags.suit,
    },
    j_wrathful_joker = {
        SMODS.meta_tags.plus_mult,
        SMODS.meta_tags.suit_spades,
        SMODS.meta_tags.suit,
    },
    j_gluttenous_joker = {
        SMODS.meta_tags.plus_mult,
        SMODS.meta_tags.suit_clubs,
        SMODS.meta_tags.suit,
    },
    j_jolly = {
        SMODS.meta_tags.plus_mult,
        SMODS.meta_tags.poker_hand,
    },
    j_zany = {
        SMODS.meta_tags.plus_mult,
        SMODS.meta_tags.poker_hand,
    },
    j_mad = {
        SMODS.meta_tags.plus_mult,
        SMODS.meta_tags.poker_hand,
    },
    j_crazy = {
        SMODS.meta_tags.plus_mult,
        SMODS.meta_tags.poker_hand,
    },
    j_droll = {
        SMODS.meta_tags.plus_mult,
        SMODS.meta_tags.poker_hand,
    },
    j_sly = {
        SMODS.meta_tags.plus_chip,
        SMODS.meta_tags.poker_hand,
    },
    j_wily = {
        SMODS.meta_tags.plus_chip,
        SMODS.meta_tags.poker_hand,
    },
    j_clever = {
        SMODS.meta_tags.plus_chip,
        SMODS.meta_tags.poker_hand,
    },
    j_devious = {
        SMODS.meta_tags.plus_chip,
        SMODS.meta_tags.poker_hand,
    },
    j_crafty = {
        SMODS.meta_tags.plus_chip,
        SMODS.meta_tags.poker_hand,
    },
    j_half = {
        SMODS.meta_tags.plus_mult,
        SMODS.meta_tags.hand_size,
    },
    j_credit_card = {
        SMODS.meta_tags.income,
    },
    j_banner = {
        SMODS.meta_tags.plus_chip,
        SMODS.meta_tags.discards,
    },
    j_mystic_summit = {
        SMODS.meta_tags.plus_mult,
        SMODS.meta_tags.discards,
    },
    j_8_ball = {
        SMODS.meta_tags.spawn_card,
        SMODS.meta_tags.probability,
        SMODS.meta_tags.tarot,
        SMODS.meta_tags.card_scored,
    },
    j_misprint = {
        SMODS.meta_tags.plus_mult,
    },
    j_raised_fist = {
        SMODS.meta_tags.plus_mult,
    },
    j_chaos = {
        SMODS.meta_tags.reroll,
    },
    j_scary_face = {
        SMODS.meta_tags.plus_chip,
        SMODS.meta_tags.face_card,
    },
    j_abstract = {
        SMODS.meta_tags.plus_mult,
        SMODS.meta_tags.joker_slot,
        SMODS.meta_tags.joker,
    },
    j_delayed_grat = {
        SMODS.meta_tags.income,
        SMODS.meta_tags.end_of_round,
        SMODS.meta_tags.discards,
    },
    j_gros_michel = {
        SMODS.meta_tags.plus_mult,
        SMODS.meta_tags.probability,
        SMODS.meta_tags.food,
    },
    j_even_steven = {
        SMODS.meta_tags.plus_mult,
        SMODS.meta_tags.card_scored,
    },
    j_odd_todd = {
        SMODS.meta_tags.plus_chip,
        SMODS.meta_tags.card_scored,
    },
    j_scholar = {
        SMODS.meta_tags.plus_mult,
        SMODS.meta_tags.plus_chip,
        SMODS.meta_tags.card_scored,
    },
    j_business = {
        SMODS.meta_tags.face_card,
        SMODS.meta_tags.income,
        SMODS.meta_tags.probability,
    },
    j_supernova = {
        SMODS.meta_tags.plus_mult,
        SMODS.meta_tags.poker_hand,
    },
    j_ride_the_bus = {
        SMODS.meta_tags.plus_mult,
        SMODS.meta_tags.face_card,
        SMODS.meta_tags.scaling,
        SMODS.meta_tags.resettable,
    },
    j_egg = {
        SMODS.meta_tags.income,
        SMODS.meta_tags.food,
        SMODS.meta_tags.sell_value,
    },
    j_runner = {
        SMODS.meta_tags.plus_chip,
        SMODS.meta_tags.poker_hand,
        SMODS.meta_tags.scaling,
    },
    j_ice_cream = {
        SMODS.meta_tags.plus_chip,
        SMODS.meta_tags.scaling,
        SMODS.meta_tags.food,
    },
    j_splash = {
        SMODS.meta_tags.card_played,
    },
    j_blue_joker = {
        SMODS.meta_tags.plus_chip,
        SMODS.meta_tags.deck,
    },
    j_faceless = {
        SMODS.meta_tags.income,
        SMODS.meta_tags.face_card,
        SMODS.meta_tags.card_discarded,
    },
    j_green_joker = {
        SMODS.meta_tags.hand_played,
        SMODS.meta_tags.card_discarded,
        SMODS.meta_tags.scaling,
    },
    j_superposition = {
        SMODS.meta_tags.spawn_card,
        SMODS.meta_tags.tarot,
        SMODS.meta_tags.card_scored,
        SMODS.meta_tags.poker_hand,
    },
    j_todo_list = {
        SMODS.meta_tags.poker_hand,
        SMODS.meta_tags.income,
    },
    j_cavendish = {
        SMODS.meta_tags.times_mult,
        SMODS.meta_tags.probability,
        SMODS.meta_tags.food,
    },
    j_red_card = {
        SMODS.meta_tags.plus_mult,
        SMODS.meta_tags.scaling,
        SMODS.meta_tags.booster_pack,
    },
    j_square = {
        SMODS.meta_tags.plus_chip,
        SMODS.meta_tags.scaling,
        SMODS.meta_tags.booster_pack,
        SMODS.meta_tags.hand_played,
    },
    j_riff_raff = {
        SMODS.meta_tags.blind_selected,
        SMODS.meta_tags.spawn_card,
        SMODS.meta_tags.joker,
    },
    j_photograph = {
        SMODS.meta_tags.face_card,
        SMODS.meta_tags.times_mult,
        SMODS.meta_tags.card_scored,
    },
    j_reserved_parking = {
        SMODS.meta_tags.face_card,
        SMODS.meta_tags.probability,
        SMODS.meta_tags.held_in_hand,
        SMODS.meta_tags.income,
    },
    j_mail = {
        SMODS.meta_tags.income,
        SMODS.meta_tags.card_discarded,
    },
    j_hallucination = {
        SMODS.meta_tags.probability,
        SMODS.meta_tags.tarot,
        SMODS.meta_tags.booster_pack,
        SMODS.meta_tags.spawn_card,
    },
    j_fortune_teller = {
        SMODS.meta_tags.tarot,
        SMODS.meta_tags.plus_mult,
        SMODS.meta_tags.scaling,
    },
    j_juggler = {
        SMODS.meta_tags.hand_size,
    },
    j_drunkard = {
        SMODS.meta_tags.discards,
    },
    j_golden = {
        SMODS.meta_tags.income,
        SMODS.meta_tags.end_of_round,
    },
    j_popcorn = {
        SMODS.meta_tags.plus_mult,
        SMODS.meta_tags.scaling,
        SMODS.meta_tags.food,
    },
    j_walkie_talkie = {
        SMODS.meta_tags.plus_mult,
        SMODS.meta_tags.plus_chip,
        SMODS.meta_tags.card_scored,
    },
    j_smiley = {
        SMODS.meta_tags.face_card,
        SMODS.meta_tags.plus_mult,
        SMODS.meta_tags.card_scored,
    },
    j_ticket = {
        SMODS.meta_tags.enhancements,
        SMODS.meta_tags.card_scored,
        SMODS.meta_tags.income,
    },
    j_swashbuckler = {
        SMODS.meta_tags.plus_mult,
        SMODS.meta_tags.sell_value,
        SMODS.meta_tags.joker,
    },
    j_hanging_chad = {
        SMODS.meta_tags.retrigger,
        SMODS.meta_tags.card_scored,
    },
    j_shoot_the_moon = {
        
    },
    j_stencil = {
        
    },
    j_four_fingers = {
        
    },
    j_mime = {
        
    },
    j_ceremonial = {
        
    },
    j_marble = {
        
    },
    j_loyalty_card = {
        
    },
    j_dusk = {
        
    },
    j_fibonacci = {
        
    },
    j_steel_joker = {
        
    },
    j_hack = {
        
    },
    j_pareidolia = {
        
    },
    j_space = {
        
    },
    j_burglar = {
        
    },
    j_blackboard = {
        
    },
    j_sixth_sense = {
        
    },
    j_constellation = {
        
    },
    j_hiker = {
        
    },
    j_card_sharp = {
        
    },
    j_madness = {
        
    },
    j_seance = {
        
    },
    j_vampire = {
        
    },
    j_shortcut = {
        
    },
    j_hologram = {
        
    },
    j_cloud_9 = {
        
    },
    j_rocket = {
        
    },
    j_midas_mask = {
        
    },
    j_luchador = {
        
    },
    j_gift = {
        
    },
    j_turtle_bean = {
        
    },
    j_erosion = {
        
    },
    j_to_the_moon = {
        
    },
    j_stone = {
        
    },
    j_lucky_cat = {
        
    },
    j_bull = {
        
    },
    j_diet_cola = {
        
    },
    j_trading = {
        
    },
    j_flash = {
        
    },
    j_trousers = {
        
    },
    j_ramen = {
        
    },
    j_selzer = {
        
    },
    j_castle = {
        
    },
    j_mr_bones = {
        
    },
    j_acrobat = {
        
    },
    j_sock_and_buskin = {
        
    },
    j_troubadour = {
        
    },
    j_certificate = {
        
    },
    j_smeared = {
        
    },
    j_throwback = {
        
    },
    j_rough_gem = {
        
    },
    j_bloodstone = {
        
    },
    j_arrowhead = {
        
    },
    j_onyx_agate = {
        
    },
    j_glass = {
        
    },
    j_ring_master = {
        
    },
    j_flower_pot = {
        
    },
    j_merry_andy = {
        
    },
    j_oops = {
        
    },
    j_idol = {
        
    },
    j_seeing_double = {
        
    },
    j_matador = {
        
    },
    j_satellite = {
        
    },
    j_cartomancer = {
        
    },
    j_astronomer = {
        
    },
    j_bootstraps = {
        
    },
    j_dna = {
        
    },
    j_vagabond = {
        
    },
    j_baron = {
        
    },
    j_obelisk = {
        
    },
    j_baseball = {
        
    },
    j_ancient = {
        
    },
    j_campfire = {
        
    },
    j_blueprint = {
        
    },
    j_wee = {
        
    },
    j_hit_the_road = {
        
    },
    j_duo = {
        
    },
    j_trio = {
        
    },
    j_family = {
        
    },
    j_order = {
        
    },
    j_tribe = {
        
    },
    j_stuntman = {
        
    },
    j_invisible = {
        
    },
    j_brainstorm = {
        
    },
    j_drivers_license = {
        
    },
    j_burnt = {
        
    },
    j_caino = {
        
    },
    j_triboulet = {
        
    },
    j_yorick = {
        
    },
    j_chicot = {
        
    },
    j_perkeo = {
        
    }
}
