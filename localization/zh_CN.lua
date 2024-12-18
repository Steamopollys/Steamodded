return {
    descriptions = {
        Other = {
            load_success = {
                text = {
                    '模组加载{C:green}成功！'
                }
            },
            load_failure_d = {
                text = {
                    '{C:attention}依赖项{}缺失！',
                    '#1#'
                }
            },
            load_failure_c = {
                text = {
                    '存在{C:attention}冲突项{}！',
                    '#1#'
                }
            },
            load_failure_d_c = {
                text = {
                    '{C:attention}依赖项{}缺失！',
                    '#1#',
                    '存在{C:attention}冲突项{}！',
                    '#2#'
                }
            },
            load_failure_o = {
                text = {
                    'Steamodded版本{C:attention}过旧{}！',
                    '已不再支持',
                    '{C:money}0.9.8{}及以下版本'
                }
            },
            load_failure_i = {
                text = {
                    '{C:attention}不兼容！',
                    '所需Steamodded版本为#1#',
                    '但当前为#2#'
                }
            },
            load_failure_p = {
                text = {
                    '{C:attention}前缀冲突！{}',
                    '此模组的前缀和',
                    '另外一个模组相同！',
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
                    '该模组',
                    '已被{C:attention}禁用{}！'
                }
            }
        },
        Edition = {
            e_negative_playing_card = {
                name = "负片",
                text = {
                    "手牌上限{C:dark_edition}+#1#"
                },
            },
        }
    },
    misc = {
        achievement_names = {
            hidden_achievement = "???",
        },
        achievement_descriptions = {
            hidden_achievement = "未发现",
        },
        dictionary = {
            b_mods = '模组',
            b_mods_cap = '模组',
            b_modded_version = '模组环境！',
            b_steamodded = 'Steamodded',
            b_credits = '鸣谢',
            b_open_mods_dir = '打开模组目录',
            b_no_mods = '未检测到任何模组……',
            b_mod_list = '已启用模组列表',
            b_mod_loader = '模组加载器',
            b_developed_by = '作者：',
            b_rewrite_by = '重写者：',
            b_github_project = 'Github项目',
            b_github_bugs_1 = '你可以在此汇报漏洞',
            b_github_bugs_2 = '和提交贡献',
            b_disable_mod_badges = '禁用模组横标',
            b_author = '作者',
            b_authors = '作者',
            b_unknown = '未知',
            b_lovely_mod = '(依赖Lovely加载器的补丁模组)',
            b_by = ' 作者：',
            b_config = "配置",
            b_additions = '新增项目',
            b_stickers = '贴纸',
            b_achievements = "成就",
            b_applies_stakes_1 = '',
            b_applies_stakes_2 = '的限制也都起效',
            b_graphics_mipmap_level = "多级渐远纹理层级",
        },
        v_dictionary = {
            c_types = '共有#1#种',
            cashout_hidden = '……还有#1#',
        },
    },

}
