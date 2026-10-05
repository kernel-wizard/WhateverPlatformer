# Calibration snapshot exporter (READ-ONLY).
# Writes Docs/snapshots/<MapName>.csv with every calibration-relevant placed actor of the
# CURRENTLY OPEN map, sorted deterministically so `git diff` shows only real changes.
# Run inside a one-shot slate post-tick callback (core.md section 4):
#   exec(open(r"<project>/Docs/tools/export_calib_snapshot.py").read(), {"__name__": "calib_snapshot"})
# Log tag: CALSNAP (grep Saved/Logs/WhateverPlatformer.log).

import unreal, csv, os, math

ROOM_W = 2560.0
ROOM_ORIGIN_X = -32.0
INCLUDE_PREFIX = "/Game/Blueprints/"
EXCLUDE_PARTS = ("/VFX/", "ParallaxLayer")
INCLUDE_ENGINE = ("PlayerStart",)

# Variables probed on every actor; only the ones that exist are written.
PARAM_NAMES = (
    "Damage", "MoveSpeed", "MoveDistance", "FallDelay", "FallSpeed", "RespawnDelay",
    "MovePlayRate", "ShootInterval", "SightRange", "ReactionDelay", "DeathDelay",
    "TurnCooldown", "WalkSpeedScale", "LevelName", "Level Name",
)
AI_PARAM_NAMES = ("ShootInterval", "SightRange", "ReactionDelay")
NAMED_COMPONENTS = ("AggroRange", "TopPos", "BottomPos")


def _f(v):
    if isinstance(v, bool):
        return "1" if v else "0"
    if isinstance(v, (int, float)):
        s = ("%.2f" % float(v)).rstrip("0").rstrip(".")
        return "0" if s in ("-0", "") else s
    return str(v)


def _prop(obj, name):
    try:
        v = obj.get_editor_property(name)
    except Exception:
        return None
    if isinstance(v, (bool, int, float, str)):
        return v
    if isinstance(v, unreal.Name):
        return str(v)
    return None


def _wanted(actor):
    path = actor.get_class().get_path_name()
    if path.startswith(INCLUDE_PREFIX):
        return not any(p in path for p in EXCLUDE_PARTS)
    return any(e in path for e in INCLUDE_ENGINE)


def export_snapshot():
    world = unreal.EditorLevelLibrary.get_editor_world()
    map_name = world.get_name()
    proj = os.path.abspath(unreal.Paths.convert_relative_path_to_full(unreal.Paths.project_dir()))
    out_dir = os.path.join(proj, "Docs", "snapshots")
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, map_name + ".csv")

    try:
        vit_cls = unreal.load_class(None, "/Game/Blueprints/Components/BPC_Vitality.BPC_Vitality_C")
    except Exception:
        vit_cls = None

    rows = []
    for a in unreal.EditorLevelLibrary.get_all_level_actors():
        if not _wanted(a):
            continue
        loc = a.get_actor_location()
        room = int(math.floor((loc.x - ROOM_ORIGIN_X) / ROOM_W))
        cls_name = a.get_class().get_name()
        if cls_name.endswith("_C"):
            cls_name = cls_name[:-2]

        hp = ""
        if vit_cls:
            comps = a.get_components_by_class(vit_cls)
            if comps:
                v = _prop(comps[0], "MaxHealth")
                hp = _f(v) if v is not None else ""

        score = _prop(a, "ScoreValue")
        params = {}
        for n in PARAM_NAMES:
            v = _prop(a, n)
            if v is not None and v != "":
                params[n.replace(" ", "")] = _f(v)

        if isinstance(a, unreal.Character):
            cmc = a.character_movement
            params["Walk"] = _f(cmc.get_editor_property("max_walk_speed"))
            params["Fly"] = _f(cmc.get_editor_property("max_fly_speed"))
            try:
                aic = a.get_editor_property("ai_controller_class")
            except Exception:
                aic = None
            if aic:
                cdo = unreal.get_default_object(aic)
                for n in AI_PARAM_NAMES:
                    v = _prop(cdo, n)
                    if v is not None:
                        params["AI." + n] = _f(v)

        for c in a.get_components_by_class(unreal.SceneComponent):
            cn = c.get_name()
            if cn not in NAMED_COMPONENTS:
                continue
            if isinstance(c, unreal.BoxComponent):
                e = c.get_scaled_box_extent()
                wl = c.get_world_location()
                params[cn] = "%s;%s@%s;%s" % (_f(e.x), _f(e.z), _f(wl.x), _f(wl.z))
            else:
                params[cn + ".Z"] = _f(c.get_editor_property("relative_location").z)

        sc = a.get_actor_scale3d()
        if abs(sc.x - 1) > 1e-3 or abs(sc.y - 1) > 1e-3 or abs(sc.z - 1) > 1e-3:
            params["Scale"] = "%s;%s;%s" % (_f(sc.x), _f(sc.y), _f(sc.z))

        rows.append([
            room, a.get_actor_label(), cls_name, _f(loc.x), _f(loc.z), hp,
            _f(score) if score is not None else "",
            "|".join("%s=%s" % (k, params[k]) for k in sorted(params)),
        ])

    rows.sort(key=lambda r: (r[0], r[2], float(r[3]), float(r[4]), r[1]))
    with open(out_path, "w", newline="", encoding="utf-8") as fh:
        w = csv.writer(fh, lineterminator="\n")
        w.writerow(["Room", "Label", "Class", "X", "Z", "HP", "Score", "Params"])
        w.writerows(rows)

    totals = {}
    for r in rows:
        t = totals.setdefault(r[0], [0, 0.0])
        t[0] += 1
        t[1] += float(r[6]) if r[6] else 0.0
    unreal.log("CALSNAP %s rows=%d -> %s" % (map_name, len(rows), out_path))
    for room in sorted(totals):
        unreal.log("CALSNAP %s R%d actors=%d score=%s" % (map_name, room, totals[room][0], _f(totals[room][1])))
    return out_path


export_snapshot()
