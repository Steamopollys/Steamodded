SMODS.meta_tags = {
    -- TODO: fill me. Kept as a separate list for convience while making it
}

local vanilla_joker_tags = {
    j_joker = {
        SMODS.meta_tags.plus_mult,
    },
    j_greedy_joker = {
        SMODS.meta_tags.plus_mult,
        SMODS.meta_tags.suit,
    },
    j_lusty_joker = {
        SMODS.meta_tags.plus_mult,
        SMODS.meta_tags.suit,
    },
    j_wrathful_joker = {
        SMODS.meta_tags.plus_mult,
        SMODS.meta_tags.suit,
    },
    j_gluttenous_joker = {
        SMODS.meta_tags.plus_mult,
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
        SMODS.meta_tags.scored_hand_size,
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
        SMODS.meta_tags.held_in_hand,
        SMODS.meta_tags.plus_mult,
    },
    j_stencil = {
        SMODS.meta_tags.times_mult,
        SMODS.meta_tags.joker_slot,
    },
    j_four_fingers = {
        SMODS.meta_tags.poker_hand,
    },
    j_mime = {
        SMODS.meta_tags.retrigger,
        SMODS.meta_tags.held_in_hand,
    },
    j_ceremonial = {
        SMODS.meta_tags.blind_selected,
        SMODS.meta_tags.sell_value,
        SMODS.meta_tags.plus_mult,
        SMODS.meta_tags.scaling,
        SMODS.meta_tags.destroy_card,
    },
    j_marble = {
        SMODS.meta_tags.blind_selected,
        SMODS.meta_tags.spawn_card,
        SMODS.meta_tags.enhancements,
    },
    j_loyalty_card = {
        SMODS.meta_tags.times_mult,
        SMODS.meta_tags.hands,
    },
    j_dusk = {
        SMODS.meta_tags.retrigger,
        SMODS.meta_tags.hand_played,
    },
    j_fibonacci = {
        SMODS.meta_tags.plus_mult,
        SMODS.meta_tags.card_scored,
    },
    j_steel_joker = {
        SMODS.meta_tags.times_mult,
        SMODS.meta_tags.full_deck,
        SMODS.meta_tags.enhancements,
    },
    j_hack = {
        SMODS.meta_tags.retrigger,
        SMODS.meta_tags.card_scored,
    },
    j_pareidolia = {
        SMODS.meta_tags.face_card,
        SMODS.meta_tags.modify_card,
    },
    j_space = {
        SMODS.meta_tags.probability,
        SMODS.meta_tags.poker_hand,
    },
    j_burglar = {
        SMODS.meta_tags.blind_selected,
        SMODS.meta_tags.discards,
        SMODS.meta_tags.hands,
    },
    j_blackboard = {
        SMODS.meta_tags.times_mult,
        SMODS.meta_tags.held_in_hand,
        SMODS.meta_tags.suit,
    },
    j_sixth_sense = {
        SMODS.meta_tags.scored_hand_size,
        SMODS.meta_tags.spawn_card,
        SMODS.meta_tags.spectral,
    },
    j_constellation = {
        SMODS.meta_tags.times_mult,
        SMODS.meta_tags.planet,
        SMODS.meta_tags.scaling,
    },
    j_hiker = {
        SMODS.meta_tags.modify_card,
        SMODS.meta_tags.card_scored,
        SMODS.meta_tags.plus_chip,
        SMODS.meta_tags.scaling,
    },
    j_card_sharp = {
        SMODS.meta_tags.times_mult,
        SMODS.meta_tags.poker_hand,
    },
    j_madness = {
        SMODS.meta_tags.blind_selected,
        SMODS.meta_tags.times_mult,
        SMODS.meta_tags.destroy_card,
        SMODS.meta_tags.scaling,
    },
    j_seance = {
        SMODS.meta_tags.poker_hand,
        SMODS.meta_tags.spawn_card,
        SMODS.meta_tags.spectral,
    },
    j_vampire = {
        SMODS.meta_tags.times_mult,
        SMODS.meta_tags.enhancements,
        SMODS.meta_tags.modify_card,
        SMODS.meta_tags.scaling,
    },
    j_shortcut = {
        SMODS.meta_tags.poker_hand,
    },
    j_hologram = {
        SMODS.meta_tags.times_mult,
        SMODS.meta_tags.deck,
    },
    j_cloud_9 = {
        SMODS.meta_tags.income,
        SMODS.meta_tags.full_deck,
        SMODS.meta_tags.end_of_round,
    },
    j_rocket = {
        SMODS.meta_tags.income,
        SMODS.meta_tags.end_of_round,
        SMODS.meta_tags.scaling,
    },
    j_midas_mask = {
        SMODS.meta_tags.card_played,
        SMODS.meta_tags.enhancements,
        SMODS.meta_tags.modify_card,
    },
    j_luchador = {
        SMODS.meta_tags.on_sell,
        SMODS.meta_tags.modify_blind,
    },
    j_gift = {
        SMODS.meta_tags.income,
        SMODS.meta_tags.sell_value,
    },
    j_turtle_bean = {
        SMODS.meta_tags.hand_size,
        SMODS.meta_tags.food,
        SMODS.meta_tags.scaling,
    },
    j_erosion = {
        SMODS.meta_tags.plus_mult,
        SMODS.meta_tags.full_deck,
    },
    j_to_the_moon = {
        SMODS.meta_tags.income,
        SMODS.meta_tags.end_of_round,
        SMODS.meta_tags.interest,
    },
    j_stone = {
        SMODS.meta_tags.plus_chip,
        SMODS.meta_tags.full_deck,
        SMODS.meta_tags.enhancements,
    },
    j_lucky_cat = {
        SMODS.meta_tags.times_mult,
        SMODS.meta_tags.enhancements,
        SMODS.meta_tags.card_scored,
        SMODS.meta_tags.scaling,
    },
    j_bull = {
        SMODS.meta_tags.plus_chip,
    },
    j_diet_cola = {
        SMODS.meta_tags.on_sell,
        SMODS.meta_tags.food,
    },
    j_trading = {
        SMODS.meta_tags.card_discarded,
        SMODS.meta_tags.destroy_card,
        SMODS.meta_tags.income,
    },
    j_flash = {
        SMODS.meta_tags.plus_mult,
        SMODS.meta_tags.reroll,
        SMODS.meta_tags.scaling,
    },
    j_trousers = {
        SMODS.meta_tags.plus_mult,
        SMODS.meta_tags.scaling,
        SMODS.meta_tags.poker_hand,
    },
    j_ramen = {
        SMODS.meta_tags.times_mult,
        SMODS.meta_tags.discards,
        SMODS.meta_tags.scaling,
        SMODS.meta_tags.food,
    },
    j_selzer = {
        SMODS.meta_tags.retrigger,
        SMODS.meta_tags.scaling,
        SMODS.meta_tags.food,
    },
    j_castle = {
        SMODS.meta_tags.plus_chip,
        SMODS.meta_tags.suit,
        SMODS.meta_tags.scaling,
    },
    j_mr_bones = {
        SMODS.meta_tags.destroy_card,
        SMODS.meta_tags.end_of_round,
        SMODS.meta_tags.prevents_death,
    },
    j_acrobat = {
        SMODS.meta_tags.times_mult,
        SMODS.meta_tags.hand_played,
    },
    j_sock_and_buskin = {
        SMODS.meta_tags.retrigger,
        SMODS.meta_tags.face_card,
    },
    j_troubadour = {
        MODS.meta_tags.hand_size,
        SMODS.meta_tags.hands,
    },
    j_certificate = {
        SMODS.meta_tags.spawn_card,
        SMODS.meta_tags.seals,
        SMODS.meta_tags.blind_selected,
    },
    j_smeared = {
        SMODS.meta_tags.suit,
    },
    j_throwback = {
        SMODS.meta_tags.times_mult,
        SMODS.meta_tags.blind_skipped,
        SMODS.meta_tags.scaling,
    },
    j_rough_gem = {
        SMODS.meta_tags.suit,
        SMODS.meta_tags.card_scored,
        SMODS.meta_tags.income,
    },
    j_bloodstone = {
        SMODS.meta_tags.suit,
        SMODS.meta_tags.card_scored,
        SMODS.meta_tags.probability,
        SMODS.meta_tags.times_mult,
    },
    j_arrowhead = {
        SMODS.meta_tags.suit,
        SMODS.meta_tags.card_scored,
        SMODS.meta_tags.plus_chip,
    },
    j_onyx_agate = {
        SMODS.meta_tags.suit,
        SMODS.meta_tags.card_scored,
        SMODS.meta_tags.plus_mult,
    },
    j_glass = {
        SMODS.meta_tags.enhancements,
        SMODS.meta_tags.times_mult,
        SMODS.meta_tags.card_destroyed,
        SMODS.meta_tags.scaling,
    },
    j_ring_master = {
        SMODS.meta_tags.allow_duplicates,
    },
    j_flower_pot = {
        SMODS.meta_tags.times_mult,
        SMODS.meta_tags.suit,
        SMODS.meta_tags.hand_played,
        SMODS.meta_tags.card_scored,
    },
    j_merry_andy = {
        SMODS.meta_tags.discards,
        SMODS.meta_tags.hand_size,
    },
    j_oops = {
        SMODS.meta_tags.probability,
    },
    j_idol = {
        SMODS.meta_tags.suit,
        SMODS.meta_tags.card_scored,
        SMODS.meta_tags.times_mult,
    },
    j_seeing_double = {
        SMODS.meta_tags.suit,
        SMODS.meta_tags.card_scored,
        SMODS.meta_tags.times_mult,
    },
    j_matador = {
        SMODS.meta_tags.boss_ability,
        SMODS.meta_tags.income,
    },
    j_satellite = {
        SMODS.meta_tags.income,
        SMODS.meta_tags.scaling,
        SMODS.meta_tags.planet,
    },
    j_cartomancer = {
        SMODS.meta_tags.blind_selected,
        SMODS.meta_tags.spawn_card,
        SMODS.meta_tags.tarot,
    },
    j_astronomer = {
        SMODS.meta_tags.planet,
        SMODS.meta_tags.modify_shop,
    },
    j_bootstraps = {
        SMODS.meta_tags.plus_mult,
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
