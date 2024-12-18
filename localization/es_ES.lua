return {
    descriptions = {
        Other = {
            load_success = {
                text = {
                    '¡Mod cargado',
                    '{C:green}con éxito{}!'
                }
            },
            load_failure_d = {
                text = {
                    '¡Faltan {C:attention}dependencias{}!',
                    '#1#',
                }
            },
            load_failure_c = {
                text = {
                    '¡Hay {C:attention}conflictos{} sin resolver!',
                    '#1#'
                }
            },
            load_failure_d_c = {
                text = {
                    '¡Faltan {C:attention}dependencias!',
                    '#1#',
                    '¡Hay {C:attention}conflictos{} sin resolver!',
                    '#2#'
                }
            },
            load_failure_o = {
                text = {
                    '¡Steamodded {C:attention}obsoleto{}!',
                    'Las versiones por debajo de {C:money}0.9.8{}',
                    'ya no tienen soporte.'
                }
            },
            load_failure_i = {
                text = {
                    '{C:attention}¡Incompatible!{} Necesita la versión',
                    '#1# de Steamodded,',
                    'pero la #2# está instalada.'
                }
            },
            load_failure_p = { -- To be translated
                text = {
                    '{C:attention}Prefix Conflict!{}',
                    'This mod\'s prefix is',
                    'the same as another mod\'s.',
                    '({C:attention}#1#{})'
                }
            },
            load_failure_m = { -- To be translated
                text = {
                    '{C:attention}Main File Not Found!{}',
                    'This mod\'s main file',
                    'could not be found.',
                    '({C:attention}#1#{})'
                }
            },
            load_disabled = {
                text = {
                    '¡Este mod ha sido',
                    '{C:attention}desactivado{}!'
                }
            }
        },
        Edition = {
            e_negative_playing_card = {
                name = "Negativa",
                text = {
                    "{C:dark_edition}+#1#{} de tamaño de mano"
                },
            },
        }
    },
    misc = {
        achievement_names = {
            hidden_achievement = "???",
        },
        achievement_descriptions = {
            hidden_achievement = "¡Juega más para descubirlo!",
        },
        dictionary = {
            b_mods = 'Mods',
            b_mods_cap = 'MODS',
            b_modded_version = 'Modded Version!', -- To be translated
            b_steamodded = 'Steamodded',
            b_credits = 'Créditos',
            b_open_mods_dir = 'Abrir directorio de Mods',
            b_no_mods = 'No se han detectado mods...',
            b_mod_list = 'Lista de Mods activos',
            b_mod_loader = 'Cargador de Mods',
            b_developed_by = 'desarrollado por ',
            b_rewrite_by = 'Reescrito por ',
            b_github_project = 'Proyecto de Github',
            b_github_bugs_1 = 'Puedes reportar errores',
            b_github_bugs_2 = 'y contribuir allí.',
            b_disable_mod_badges = 'Desactivar insignias de mods',
            b_author = 'Autor/a',
            b_authors = 'Autores',
            b_unknown = 'Desconocido',
            b_lovely_mod = '(Lovely Mod) ', --TODO
            b_by = ' Por: ',
            b_config = "Configuración",
            b_additions = 'Adiciones',
            b_stickers = 'Stickers', -- TODO
            b_achievements = "Logros",
            b_applies_stakes_1 = 'Aplica ',
            b_applies_stakes_2 = '',
            b_graphics_mipmap_level = "Mipmap level", -- TODO
        },
        v_dictionary = {
            c_types = '#1# Tipos',
            cashout_hidden = '...y #1# más',
        },
    }
}
